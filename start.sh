#!/bin/bash
require 'dotenv/load'

export $(cat .env | xargs)

# ruby ./scripts/redmine/redmine_ticket_child_ids.rb
ruby ./scripts/redmine/test.rb
