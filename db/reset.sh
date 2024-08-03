#!/bin/bash

rake db:environment:set
rake db:drop
rake db:setup
