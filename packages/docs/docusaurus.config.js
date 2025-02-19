const lightCodeTheme = require('prism-react-renderer/themes/palenight')
const darkCodeTheme = require('prism-react-renderer/themes/vsDark')

const sitePlugin = require('./src/plugin')
const rehypeLoader = require('./src/util/rehypePlugins')

const DEBUG = process.env.NODE_ENV !== 'production'

const COUNTLY_KEY = process.env.COUNTLY_KEY || 'TEST_KEY'
const COUNTLY_URL = process.env.COUNTLY_URL || 'https://countly.protocol.ai'

const ALGOLIA_KEY = process.env.ALGOLIA_KEY || '358b95b4567a562349f2c806c152fada'
const ALGOLIA_INDEX = process.env.ALGOLIA_INDEX || 'web3-storage-docusaurus'
const ALGOLIA_APP_ID = process.env.ALGOLIA_APP_ID || '9ARXAK1OFV'

/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'Web3.Storage Documentation',
  tagline: 'Better storage. Better transfers. Better internet.',
  url: 'https://web3.storage/',
  baseUrl: '/docs/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'web3-storage',
  projectName: 'web3.storage',
  themeConfig: {
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },
    navbar: {
      title: 'Web3.Storage',
      logo: {
        alt: 'Web3.Storage Logo',
        src: 'img/logo.svg',
        srcDark: 'img/logo-dark.svg',
        href: 'https://web3.storage'
      },
      items: [
        {
          label: 'About',
          position: 'right',
          href: 'https://web3.storage/about'
        },
        {
          label: 'Pricing',
          position: 'right',
          href: 'https://web3.storage/pricing'
        },
        {
          label: 'FAQ',
          position: 'right',
          href: 'https://web3.storage/faq'
        },
        {
          label: 'Docs',
          type: 'doc',
          docId: 'intro',
          position: 'right'
        },
        {
          label: 'Sign In',
          position: 'right',
          href: 'https://web3.storage/login'
        },
        {
          type: 'search',
          position: 'right'
        }
      ]
    },

    footer: {
      copyright: '<div class="footer--made-with">2021 <a href="https://protocol.ai" target="_blank" rel="noopener noreferrer" data-v-13c85306="" data-v-2294af70="">Protocol Labs</a></div>',
      links: [
        {
          items: [
            {
              label: 'Status',
              href: 'https://status.web3.storage/'
            },
            {
              label: 'Terms of Service',
              href: 'https://web3.storage/terms'
            },
            {
              label: 'Open an issue',
              href: 'https://github.com/web3-storage/web3.storage/issues/new/choose'
            },
            {
              label: 'Contact us',
              href: '/community/help-and-support'
            }
          ]
        }
      ]
    },
    prism: {
      theme: lightCodeTheme,
      darkTheme: darkCodeTheme
    },

    algolia: {
      apiKey: ALGOLIA_KEY,
      indexName: ALGOLIA_INDEX,
      appId: ALGOLIA_APP_ID
    },

    countly: {
      appKey: COUNTLY_KEY,
      countlyUrl: COUNTLY_URL
    },

    redoc: {
      typography: {
        fontFamily: 'SuisseIntl',
        fontSize: '16px',
        headings: {
          fontFamily: 'SuisseIntl',
          fontWeight: '600'
        }
      },
      lightThemeColors: {
        background: '#f1f1f1',
        headers: '#03040a',
        primary: '#3C3CD0',
        secondary: '#3C3CD0',
        text: '#03040a',
        contrastText: '#fff',
        tableRowBackground: 'transparent',
        tableRowAltBackground: 'transparent',
        responsePanelBackground: 'transparent',
        codeBlockBackground: '#1c1e29'
      },
      darkThemeColors: {
        background: '#2d2d65',
        headers: '#fde956',
        text: '#fff',
        tableRowBackground: '#2d2d65',
        tableRowAltBackground: '#3f3f75',
        codeBlockBackground: '#1e1e1e'
      }
    }
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          sidebarCollapsible: false,
          editUrl: 'https://github.com/web3-storage/docs/edit/main/',
          showLastUpdateTime: true,
          routeBasePath: '/',
          remarkPlugins: [
            require('remark-docusaurus-tabs')
          ],
          rehypePlugins: [
            rehypeLoader
          ]
        },
        blog: false,
        theme: {
          customCss: require.resolve('./src/css/custom.scss')
        }
      }
    ],

    'redocusaurus'
  ],
  plugins: [
    'docusaurus-plugin-sass',
    ['@docusaurus/plugin-client-redirects', {
      redirects: [
        {
          from: '/http-api.html',
          to: '/reference/http-api/'
        },
        {
          from: '/http-api/',
          to: '/reference/http-api/'
        },
        {
          from: '/reference/client-library',
          to: '/reference/js-client-library'
        }
      ]
    }],

    sitePlugin
  ]
}
