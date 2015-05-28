#!/bin/bash
#where am i? move to where I am. This ensures source is properly sourced
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

source ../../config/scripts/drush-create-site/config.cfg

#provide messaging colors for output to console
txtbld=$(tput bold)             # Bold
bldgrn=${txtbld}$(tput setaf 2) #  green
bldred=${txtbld}$(tput setaf 1) #  red
txtreset=$(tput sgr0)
elmslnecho(){
  echo "${bldgrn}$1${txtreset}"
}
elmslnwarn(){
  echo "${bldred}$1${txtreset}"
}
# Define seconds timestamp
timestamp(){
  date +"%s"
}

#test for empty vars. if empty required var -- exit
if [ -z $elmsln ]; then
  elmslnwarn "please update your config.cfg file"
  exit 1
fi

# to decrease risk of a WSOD when there are significant shifts
# under the hood, we should run RRs prior to the rest of the routine
elmslnecho "Rebuilding registies and caches for all systems"
drush @elmsln rr --y
# run the safe upgrade of projects by taking the site offline then back on
elmslnecho "Running update hooks"
drush @elmsln cook dr_run_updates --y
# run global upgrades from drup recipes
drush @elmsln drup d7_elmsln_global ${elmsln}/scripts/upgrade/drush_recipes/d7/global --y
# trigger crons to run now that these sites are all back and happy
elmslnecho "Run crons as clean up"
drush @elmsln cron --y
# now loop through and prime the caches on everything
elmslnecho "Seeding caches of all entities"
drush @elmsln ecl --y

# stacks we currently are supporting for these type of upgrades
# @todo look into pushing this info off onto the cfg file as well
# this way we can read from this source after they've already set the
# whole network in motion as to what they want to support. It will also
# give us flexibility to add a command to pull new tools into this network
# and in the future allow for clustered elmsln instances where parts of
# the network are upgraded and managed locally per system install without
# the possibility of having other stacks written into this one.
stacklist=('online' 'media' 'courses' 'studio' 'interact' 'blog' 'discuss' 'comply')
for stack in "${stacklist[@]}"
do
  elmslnecho "Applying specific upgrades against $stack"
  # run stack specific upgrades if they exist
  drush @${stack}-all drup d7_elmsln_${stack}-all ${elmsln}/scripts/upgrade/drush_recipes/d7/${stack}-all --y
done