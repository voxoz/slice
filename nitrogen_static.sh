#!/bin/bash

N2O=deps/n2o/priv/static
FILES=apps/web/priv/static/nitrogen
BOOTSTRAP=apps/web/priv/static/bootstrap
FONTAWESOME=apps/web/priv/static/font-awesome
LESSJS=apps/web/priv/static/less
rm -rf $FILES
rm -rf $N2O
rm -rf $BOOTSTRAP
rm -rf $FONTAWESOME
rm -rf $LESSJS
ln -s ../../n2o_scripts $N2O
ln -s ../../../../deps/n2o/priv/static/n2o $FILES
ln -s ../../../../deps/n2o/priv/static/bootstrap $BOOTSTRAP
ln -s ../../../../deps/n2o/priv/static/font-awesome $FONTAWESOME
ln -s ../../../../deps/n2o/priv/static/less $LESSJS
