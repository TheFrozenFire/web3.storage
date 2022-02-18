-- Auth key blocked status type is the type of blocking that has occurred on the api
-- key.  These are primarily used by the admin app.
CREATE TYPE auth_key_blocked_status_type AS ENUM
(
  -- The api key is blocked.
  'Blocked',
  -- The api key is unblocked.
  'Unblocked'
);

-- User tags are associated to a user for the purpose of granting/restricting them
-- in the application.
CREATE TYPE user_tag_type AS ENUM
(
  'ACCOUNT_ENABLED',
  'PSA_ENABLED',
  'STORAGE_LIMIT_BYTES'
);

CREATE TYPE user_tag_value_type AS ENUM
(
  'bigint',
  'boolean',
  'integer',
  'real',
  'text'
);

CREATE TYPE user_tag_proposal_decision_type AS ENUM
(
  'Approved',
  'Declined'
);

-- A user of web3.storage.
CREATE TABLE IF NOT EXISTS public.user
(
  id              BIGSERIAL PRIMARY KEY,
  name            TEXT                                                          NOT NULL,
  picture         TEXT,
  email           TEXT                                                          NOT NULL,
  -- The Decentralized ID of the Magic User who generated the DID Token.
  issuer          TEXT                                                          NOT NULL UNIQUE,
  -- GitHub user handle, may be null if user logged in via email.
  github          TEXT,
  -- Cryptographic public address of the Magic User.
  public_address  TEXT                                                          NOT NULL UNIQUE,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
CREATE INDEX IF NOT EXISTS user_updated_at_idx ON public.user (updated_at);

-- These are active user_tags that a user has (no joins required).  Admins can add
-- to this table at will, with or without there first being an entry in user_tag_proposal.
CREATE TABLE IF NOT EXISTS public.user_tag
(
  id              BIGSERIAL PRIMARY KEY,
  user_id         BIGINT                                                        NOT NULL REFERENCES public.user (id),
  tag             user_tag_type                                                 NOT NULL,
  value           TEXT                                                          NOT NULL,
  value_type      user_tag_value_type                                           NOT NULL,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())     NOT NULL,
  deleted_at  TIMESTAMP WITH TIME ZONE
);
-- Note: We index active user_tags with deleted_at IS NULL to enforce only 1 active
-- tag type per user.  We allow there to be multiple deleted user_tags of the same type per
-- user to handle the scenario where a user has had a tag removed multiple times by
-- admins.
CREATE UNIQUE INDEX IF NOT EXISTS user_tag_is_not_deleted_idx ON user_tag (user_id, tag)
WHERE deleted_at IS NULL;

-- These are where admin deletion reasons are stored.  These aren't needed by the application
-- and are therefore stored separately from the active user_tags.
CREATE TABLE IF NOT EXISTS public.user_tag_deletion_reasons
(
  id              BIGSERIAL PRIMARY KEY,
  user_tag_id     BIGINT                                                        NOT NULL REFERENCES public.user_tag (id),
  reason          TEXT                                                          NOT NULL,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())     NOT NULL
);

-- These are user_tags that a user has requested.  It is assumed that a user can only request
-- one type of user_tag at any given time, hence the index associated with this table.
-- This table should likely be joined with the user_tag_proposal_decision table to
-- show the current decision of admins to approve or decline said requests.  These
-- proposals are visible to both users and admins.
CREATE TABLE IF NOT EXISTS public.user_tag_proposal
(
  id              BIGSERIAL PRIMARY KEY,
  user_id         BIGINT                                                        NOT NULL REFERENCES public.user (id),
  tag             user_tag_type                                                 NOT NULL,
  value           TEXT                                                          NOT NULL,
  value_type      user_tag_value_type                                           NOT NULL,
  proposal        TEXT                                                          NOT NULL,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())     NOT NULL,
  deleted_at  TIMESTAMP WITH TIME ZONE
);
-- Note: We index active user_tag_proposals with deleted_at IS NULL to enforce only 1 active
-- tag type proposal per user.  We allow there to be multiple deleted user_tag_proposals of the same type per
-- user to handle the scenario where a user has been denied multiple times by admins.
-- If deleted_at is populated, it means the user_tag_proposal has been cancelled by
-- a user or a decision in user_tag_proposal_decision has been provided by an admin.
CREATE UNIQUE INDEX IF NOT EXISTS user_tag_proposal_is_not_deleted_idx ON user_tag_proposal (user_id, tag)
WHERE deleted_at IS NULL;

-- This table stores decisions made by admins to Approve or Decline a user_tag_proposal.
CREATE TABLE IF NOT EXISTS public.user_tag_proposal_decision
(
  id                   BIGSERIAL PRIMARY KEY                                            ,
  user_tag_proposal_id BIGINT                                                   NOT NULL REFERENCES public.user_tag_proposal (id),
  decision             TEXT                                                             ,
  decision_type        user_tag_proposal_decision_type                                  ,
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())     NOT NULL,
  deleted_at  TIMESTAMP WITH TIME ZONE
);
-- A deleted decision means that it is likely no longer needed in joins and is only
-- preserved in the DB for historical purposes.
CREATE UNIQUE INDEX IF NOT EXISTS user_tag_proposal_decision_is_not_deleted_idx ON user_tag_proposal_decision (user_id, tag)
WHERE deleted_at IS NULL;

-- User authentication keys.
CREATE TABLE IF NOT EXISTS auth_key
(
  id              BIGSERIAL PRIMARY KEY,
  -- User assigned name.
  name            TEXT                                                          NOT NULL,
  -- Secret that corresponds to this token.
  secret          TEXT                                                          NOT NULL,
  -- User this token belongs to.
  user_id         BIGINT                                                        NOT NULL REFERENCES public.user (id),
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at      TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS auth_key_user_id_idx ON auth_key (user_id);

CREATE TABLE IF NOT EXISTS auth_key_history
(
  id          BIGSERIAL PRIMARY KEY,
  status      auth_key_blocked_status_type                                  NOT NULL,
  reason      TEXT                                                          NOT NULL,
  auth_key_id BIGSERIAL                                                     NOT NULL REFERENCES auth_key (id),
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at  TIMESTAMP WITH TIME ZONE
);

-- Details of the root of a file/directory stored on web3.storage.
CREATE TABLE IF NOT EXISTS content
(
  -- Root CID for this content. Normalized as v1 base32.
  cid             TEXT PRIMARY KEY,
  -- Size of the DAG in bytes. Either the cumulativeSize for dag-pb or the sum of block sizes in the CAR.
  dag_size        BIGINT,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS content_inserted_at_idx ON content (inserted_at);
CREATE INDEX IF NOT EXISTS content_updated_at_idx ON content (updated_at);
-- TODO: Sync with @ribasushi as we can start using this as the primary key
CREATE UNIQUE INDEX content_cid_with_size_idx ON content (cid) INCLUDE (dag_size);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'pin_status_type') THEN

    -- IPFS Cluster tracker status values.
    -- https://github.com/ipfs/ipfs-cluster/blob/54c3608899754412861e69ee81ca8f676f7e294b/api/types.go#L52-L83
    -- TODO: nft.storage only using a subset of these: https://github.com/ipfs-shipyard/nft.storage/blob/main/packages/api/db/tables.sql#L2-L7
    CREATE TYPE pin_status_type AS ENUM
    (
      -- Should never see this value. When used as a filter. It means "all".
      'Undefined',
      -- The cluster node is offline or not responding.
      'ClusterError',
      -- An error occurred pinning.
      'PinError',
      -- An error occurred unpinning.
      'UnpinError',
      -- The IPFS daemon has pinned the item.
      'Pinned',
      -- The IPFS daemon is currently pinning the item.
      'Pinning',
      -- The IPFS daemon is currently unpinning the item.
      'Unpinning',
      -- The IPFS daemon is not pinning the item.
      'Unpinned',
      -- The IPFS daemon is not pinning the item but it is being tracked.
      'Remote',
      -- The item has been queued for pinning on the IPFS daemon.
      'PinQueued',
      -- The item has been queued for unpinning on the IPFS daemon.
      'UnpinQueued',
      -- The IPFS daemon is not pinning the item through this CID but it is tracked
      -- in a cluster dag
      'Sharded'
    );
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'upload_type') THEN
    -- Upload type is the type of received upload data.
    CREATE TYPE upload_type AS ENUM
    (
      -- A CAR file upload.
      'Car',
      -- Files uploaded and converted into a CAR file.
      'Upload',
      -- A raw blob upload in the request body.
      'Blob',
      -- A multi file upload using a multipart request.
      'Multipart'
      -- Note: "Remote" is reserved by dagcargo to identify PSA pin request
      -- "uploads" and cannot be used here!
    );
  END IF;
END$$;

-- An IPFS node that is pinning content.
CREATE TABLE IF NOT EXISTS pin_location
(
  id              BIGSERIAL PRIMARY KEY,
  -- Libp2p peer ID of the node pinning this pin.
  peer_id         TEXT                                                          NOT NULL UNIQUE,
  -- Name of the peer pinning this pin.
  peer_name       TEXT,
  -- Geographic region this node resides in.
  region          TEXT
);

-- Information for piece of content pinned in IPFS.
CREATE TABLE IF NOT EXISTS pin
(
  id              BIGSERIAL PRIMARY KEY,
  -- Pinning status at this location.
  status          pin_status_type                                               NOT NULL,
  -- The content being pinned.
  content_cid     TEXT                                                          NOT NULL REFERENCES content (cid),
  -- Identifier for the service that is pinning this pin.
  pin_location_id BIGINT                                                        NOT NULL REFERENCES pin_location (id),
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (content_cid, pin_location_id)
);

CREATE INDEX IF NOT EXISTS pin_location_id_idx ON pin (pin_location_id);
CREATE INDEX IF NOT EXISTS pin_updated_at_idx ON pin (updated_at);
CREATE INDEX IF NOT EXISTS pin_status_idx ON pin (status);
CREATE INDEX IF NOT EXISTS pin_composite_updated_at_and_content_cid_idx ON pin (updated_at, content_cid);

-- An upload created by a user.
CREATE TABLE IF NOT EXISTS upload
(
  id              BIGSERIAL PRIMARY KEY,
  -- User that uploaded this content.
  user_id         BIGINT                                                        NOT NULL REFERENCES public.user (id),
  -- User authentication token that was used to upload this content.
  -- Note: nullable, because the user may have used a Magic.link token.
  auth_key_id     BIGINT REFERENCES auth_key (id),
  -- The root of the uploaded content (base32 CIDv1 normalised).
  content_cid     TEXT                                                          NOT NULL REFERENCES content (cid),
  -- CID in the from we found in the received file.
  source_cid      TEXT                                                          NOT NULL,
  -- Type of received upload data.
  type            upload_type                                                   NOT NULL,
  -- User provided name for this upload.
  name            TEXT,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at      TIMESTAMP WITH TIME ZONE,
  UNIQUE (user_id, source_cid)
);

CREATE INDEX IF NOT EXISTS upload_auth_key_id_idx ON upload (auth_key_id);
CREATE INDEX IF NOT EXISTS upload_content_cid_idx ON upload (content_cid);
CREATE INDEX IF NOT EXISTS upload_updated_at_idx ON upload (updated_at);

-- Details of the backups created for an upload.
CREATE TABLE IF NOT EXISTS backup
(
  id              BIGSERIAL PRIMARY KEY,
  -- Upload that resulted in this backup.
  upload_id       BIGINT                                                        NOT NULL REFERENCES upload (id) ON DELETE CASCADE,
  -- Backup url location.
  url             TEXT                                                          NOT NULL,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE (upload_id, url)
);

CREATE INDEX IF NOT EXISTS backup_upload_id_idx ON backup (upload_id);

-- Tracks requests to replicate content to more nodes.
CREATE TABLE IF NOT EXISTS pin_request
(
  id              BIGSERIAL PRIMARY KEY,
  -- Root CID of the Pin we want to replicate.
  content_cid     TEXT                                                          NOT NULL UNIQUE REFERENCES content (cid),
  attempts        INT DEFAULT 0,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS pin_request_content_cid_idx ON pin_request (content_cid);

-- A request to keep a Pin in sync with the nodes that are pinning it.
CREATE TABLE IF NOT EXISTS pin_sync_request
(
  id              BIGSERIAL PRIMARY KEY,
  -- Identifier for the pin to keep in sync.
  pin_id          BIGINT                                                        NOT NULL UNIQUE REFERENCES pin (id),
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS pin_sync_request_pin_id_idx ON pin_sync_request (pin_id);

-- Setting search_path to public scope for uuid function(s)
SET search_path TO public;
DROP extension IF EXISTS "uuid-ossp";
CREATE extension "uuid-ossp" SCHEMA public;

-- Tracks pinning requests from Pinning Service API
CREATE TABLE IF NOT EXISTS psa_pin_request
(
  -- TODO - Vlaidate UUID type is available
  id              TEXT DEFAULT public.uuid_generate_v4() PRIMARY KEY,
  -- Points to auth key used to pin the content.
  auth_key_id     BIGINT                                                       NOT NULL REFERENCES public.auth_key (id),
  content_cid     TEXT                                                         NOT NULL REFERENCES content (cid),
  -- The id of the content being requested, it could not exist on IPFS (typo, node offline etc).
  source_cid      TEXT NOT NULL,
  name            TEXT,
  -- User provided multiaddrs of origins of this upload.
  origins         jsonb,
  -- Custom metadata provided by the user.
  meta            jsonb,
  deleted_at      TIMESTAMP WITH TIME ZONE,
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS name
(
    -- base36 "libp2p-key" encoding of the public key
    key         TEXT PRIMARY KEY,
    -- the serialized IPNS record - base64 encoded
    record      TEXT NOT NULL,
    -- next 3 fields are derived from the record & used for newness comparisons
    -- see: https://github.com/ipfs/go-ipns/blob/a8379aa25ef287ffab7c5b89bfaad622da7e976d/ipns.go#L325
    has_v2_sig  BOOLEAN NOT NULL,
    seqno       BIGINT NOT NULL,
    validity    BIGINT NOT NULL, -- nanoseconds since 00:00, Jan 1 1970 UTC
    inserted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS pinning_authorization
(
  id              BIGSERIAL PRIMARY KEY,
  -- Points to user allowed to pin content.
  user_id         BIGINT                                                        NOT NULL REFERENCES public.user (id),
  inserted_at     TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  deleted_at      TIMESTAMP WITH TIME ZONE
);

CREATE VIEW admin_search as
select
  u.id::text as user_id,
  u.email as email,
  ak.secret as token,
  ak.id::text as token_id,
  ak.deleted_at as deleted_at,
  akh.inserted_at as reason_inserted_at,
  akh.reason as reason,
  akh.status as status
from public.user u
right join auth_key ak on ak.user_id = u.id
full outer join (select * from auth_key_history where deleted_at is null) as akh on akh.auth_key_id = ak.id
where ak.deleted_at is NULL or ak.deleted_at is not NULL and akh.status is not NULL;
