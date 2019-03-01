#!/bin/bash

# Use 'environment'
rm $HOME/.profile
ln -s $HOME/environment/login $HOME/.profile
rm $HOME/.bashrc
ln -s $HOME/environment/environment $HOME/.bashrc
rm $HOME/.bash_logout
ln -s $HOME/environment/logout $HOME/.bash_logout
