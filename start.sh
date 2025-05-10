#!/bin/bash

echo "Starting PlanningDistro..."
echo "Make sure you have set your Google API credentials in Rails credentials."
echo "You can get these credentials from https://console.developers.google.com/"
echo "To edit credentials: rails credentials:edit"
echo ""

# Start the Rails server
bundle exec rails server