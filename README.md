<h1 align="center">⁂<br/>web3.storage</h1>
<p align="center">The simple file storage service for IPFS &amp; Filecoin.</p>

## Getting started

This project uses node v16 and npm v7. It's a monorepo that use [npm workspaces](https://docs.npmjs.com/cli/v7/using-npm/workspaces) to handle resolving dependencies between the local `packages/*` folders.

You need an account on https://magic.link, and Docker running locally.

Copy the <.env.tpl> file to `.env` and set the values for the `MAGIC_SECRET_KEY` & `NEXT_PUBLIC_MAGIC`, from your magic.link account dashboard.

Then install the deps with `npm` and then run all the things with `npm start`

```console
# install deps
npm install

# start the api and website
npm start
```

To be able to run the APIs you need to make sure the underlying DB is populated with the required tables.
Please follow the instructions in the [Populate Database](./packages/db/README.md#2-populate-database) section in the db package README.


To add a new workspace to the repo:

```console
npm init -w ./packages/website
```

To run an npm script in one or more workspaces

```console
npm run test --workspace=a --workspace=b
```

## Testing

Each workspace has its own suite of testing tools, which you can learn more about in the relevant `packages/*` directory. Check out highlights in each readme using the links below, then dig into the relevant `package.json` file for a full list of available scripts. 
- [Website](https://github.com/web3-storage/web3.storage/tree/main/packages/website#readme) (packages/website)
- [JavaScript API client](https://github.com/web3-storage/web3.storage/tree/main/packages/client#readme) (packages/client)
- [HTTP API client](https://github.com/web3-storage/web3.storage/tree/main/packages/api#readme) (packages/api)
- [CLI](https://github.com/web3-storage/web3.storage/tree/main/packages/w3#readme) (packages/w3)
- [Cron jobs](https://github.com/web3-storage/web3.storage/tree/main/packages/cron#readme) (packages/cron)
- [Database](https://github.com/web3-storage/web3.storage/tree/main/packages/db#readme) (packages/db)

Our docs website is currently hosted in a [separate repo](https://github.com/web3-storage/docs), but you can test it too!

## Learn more
To learn more about the Web3.Storage service, upload a file through our friendly UI, or find detailed documentation for the JS client library, please head over to https://web3.storage


<p align="center">
  <a href="https://web3.storage">⁂</a>
</p>
