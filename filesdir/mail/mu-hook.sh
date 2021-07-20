#!/usr/bin/env bash

mu index

bbc exec "$(bbc list | grep mail | awk '{print $1}')"
