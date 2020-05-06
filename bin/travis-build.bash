#!/bin/bash
set -e

echo "This is travis-build.bash..."
echo "Targetting CKAN $CKANVERSION on Python $TRAVIS_PYTHON_VERSION"

echo "Installing the packages that CKAN requires..."
sudo apt-get update -qq
sudo apt-get install solr-jetty

make ckan-install CKAN_VERSION=$CKANVERSION

echo "Setting up Solr..."
# solr is multicore for tests on ckan master now, but it's easier to run tests
# on Travis single-core still.
# see https://github.com/ckan/ckan/issues/2972
sed -i -e 's/solr_url.*/solr_url = http:\/\/127.0.0.1:8983\/solr/' ckan/test-core.ini
printf "NO_START=0\nJETTY_HOST=127.0.0.1\nJETTY_PORT=8983\nJAVA_HOME=$JAVA_HOME" | sudo tee /etc/default/jetty
sudo cp ckan/ckan/config/solr/schema.xml /etc/solr/conf/schema.xml
sudo service jetty restart

echo "Creating the PostgreSQL user and database..."
sudo -u postgres psql -c "CREATE USER ckan WITH PASSWORD 'ckan';"
sudo -u postgres psql -c "CREATE USER datastore_ro WITH PASSWORD 'datastore_ro';"
sudo -u postgres psql -c 'CREATE DATABASE ckan_test WITH OWNER ckan;'
sudo -u postgres psql -c 'CREATE DATABASE datastore_test WITH OWNER ckan;'

echo "travis-build.bash is done."
