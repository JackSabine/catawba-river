#!/bin/bash

export WORKAREA="${PWD}"
export SCRIPTS_ROOT="${WORKAREA}/scripts"
scripts=("${SCRIPTS_ROOT}/qsim")

export DV_REGRESSION_LISTS_DIR="${WORKAREA}/dv/regressions"
export DV_MODELS="${WORKAREA}/dv/model"
export DV_DPI_C="${DV_MODELS}/dpi-c"

export WORKDIR="${WORKAREA}/work"
export REGRDIR="${WORKAREA}/regr"
for s in "${scripts[@]}"; do
  export PATH="${s}:${PATH}"
done

alias waves="xsim -autoloadwcfg --gui *_snapshot.wdb &"
