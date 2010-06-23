# NRUNS = how many times to run the benchmarks for each version of wine
# Can't run before wine-1.1.5, doesn't compile with ubuntu 10.04
# Can't run before wine-1.1.36, needs a different patch for 3dmark06
# without a patch
export NRUNS=3
sh -x yagmark-series.sh kegel.com:public_html/kegel/wine/yagmarkdata/ \
  wine-1.1.36 \
  wine-1.1.37 \
  wine-1.1.38 \
  wine-1.1.39 \
  wine-1.1.40 \
  wine-1.1.41 \
  wine-1.1.42 \
  wine-1.1.43 \
  wine-1.1.44 \
  wine-1.2-rc1 \
  wine-1.2-rc2 \
  wine-1.2-rc3 \
  wine-1.2-rc4
