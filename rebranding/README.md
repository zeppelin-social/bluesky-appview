Rebranding
==========

This is a set of useful utilities for rebranding the Bluesky source tree, as well as particular configurations of that rebranding
The rebranding supports changes to brand names and images, theming styles, and also domain names.
Ideally, the source tree should support the domain names changing based on environment variables, but this is not always the case.

Rebranding is done using:
- semgrep to alter source code and configuration
- comby.dev to replace svg content in tsx files
- inkscape to extract images from SVG source graphic files
- python for some management and processing

Installation
------------

- install semgrep
- install comby.dev
- install python
- create a python virtual environment in venv and activate
- pip install -r requirements.txt

Inkscape
--------

This uses command-line scripting of inkscape to export the graphics.
It also uses Python to simplify exported SVG where that is needed.

Structure
=========

It's possible to support multiple different rebranding configurations, with a directory that contains the configurations.
Each repo that needs to be patched has a separate .yml file which governs the patching.
The .yml files follow semgrep syntax, with some additions for image processing

The graphics rebranding is stored in a separate directory, since it is somewhat independ of domain names

Opensky
-------

There is a generic "opensky.local.com" configuration included as an example, in `opensky-local-com/*.yml`
To use this, copy the `.yml` files to an appropriate directory and adjust the domain parameters.

At present, it has a rebranding configuration for the social-app which presents the frontend for Bluesky,
and for atproto because the pds package sends out some emails which need rebranding.

Exporting Images
================

Run `opensky/export-brand-images.py` to generate the bitmap and smaller svg images from the main branding svg

Running from Parent
===================

The script in the parent directory, `../step30-build-branded.sh`, can run these branding changes
To use it, in the `bluesky-params.env` you create, set `REBRANDING_SCRIPT` to `rebranding/run-rewrite.sh`,
and set `REBRANDING_NAME` to match the name you chose to replace `opensky-local-com`.

Running Manually
================

Applying Branding Changes
-------------------------

The code assumes the layout of bluesky-selfhost-env from the parent directory.

The directories can be overridden in `bluesky-params.env` in the parent directory.

IMPORTANT: Take care, as the script wipes out changes every time it applies branding things.
It's intended to use with the parent directory scripted process.

Run: `run-rewrite.sh opensky-local-com opensky` to apply the opensky.local.com rules with the opensky graphics

Dev Environment
---------------

Then to run the patched code in a dev environment:

* In atproto, use the Makefile to run: `make run-dev-env-logged` - this runs the supporting services, but not the web app
* In social-app, run `yarn web` (after doing installation) - this runs the live-reloading dev version of the web app
  - To run the production web app, run `yarn build-web`, and then run the go server following social-app/bskyweb/README.md

