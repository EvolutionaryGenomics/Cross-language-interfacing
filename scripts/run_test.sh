#! /bin/bash
#
#  ./scripts/run_test.sh --once &> short.log
#  grep -e '^=\|^[[:digit:]]' full.log > results.txt
#
#  Copyright (C) 2011 Pjotr Prins <pjotr.prins@thebird.nl> 
 
testname=$1
if [ "$testname" == "--once" ]; then
  quick=1
  testname=$2
  shift
fi
if [ "$testname" == "--short" ]; then
  quick=true
  testname=$2
  shift
fi
if [ "$testname" == "--commands" ]; then
  showcmd=true
  testname=$2
fi

killall RSOAPManager
killall Rserve

echo $testname
echo $quick

function runtest {
  if [ -z $testname ] || [ "$testname" == "$short" ]; then
    echo "# Running $descr"
    for pkg in $pkgs ; do
      echo -n "# "
      dpkg-query -W $pkg
    done
    # fill OS buffers
    for testsize in $testsizes ; do
      testfn=/tmp/test-dna-${testsize}.fa
      fullcmd="$cmd"
      if [ ! -z $showcmd ]; then
        echo $timer $fullcmd $testfn
      else
        # Dummy run
        $fullcmd $testfn > /dev/null
        for x in $repeat ; do 
          echo -en "=\t$short\t$testsize\t"
          # var=$(time (echo 1 > /dev/null ) 2>&1 )
          $timer $fullcmd 2>&1 $testfn > /dev/null 
        done
      fi
    done
  fi
}

function runRtest {
  if [ -z $testname ] || [ "$testname" == "$short" ]; then
    echo "# Running $descr"
    for pkg in $pkgs ; do
      echo -n "# "
      dpkg-query -W $pkg
    done
    # fill OS buffers
    fullcmd="/usr/bin/time -f %e env BATCH_VARS="$testfn" R -q --no-save --no-restore --no-readline --slave < $cmd > /dev/null"
    if [ ! -z $showcmd ]; then
      echo $fullcmd
    else
      for testsize in $testsizes ; do
        echo -en "=\t$short\t$testsize\t"
        testfn=/tmp/test-dna-${testsize}.fa
        # echo "/usr/bin/time -f %e env BATCH_VARS="$testfn" R -q --no-save --no-restore --no-readline --slave < $cmd > /dev/null"
        $timer env BATCH_VARS="$testfn" R -q --no-save --no-restore --no-readline --slave < $cmd > /dev/null
      done
    fi
  fi

}

timer="/usr/bin/time -f %e"
if [ ! -z $quick ] ; then
  if [ $quick == "1" ]; then
    testsizes="50"
  else
    testsizes="100 500 1000"
  fi
  repeat="1"
else
  testsizes="500 1000 5000 15000 24652"
  repeat="1"
fi

cat /proc/version
if false ; then
pkgs="python python-rpy2 python-biopython"
short="RPy2"
descr="RPy2+GeneR"
cmd="python src/RS/RPy2/DNAtranslate_RPy2.py"
runtest
pkgs="python python-rpy r-base r-cran-rserve r-cran-rjava default-jdk"
short="Python+Rserve"
descr=$short
cmd="python src/RServe/python/DNAtranslate.py"
runtest
pkgs="python r-base python-biopython"
short="Python+RSOAP"
descr="Python+RSOAP+GeneR"
cmd="src/RSOAP/python/DNAtranslate_RSOAP.py"
runtest
pkgs="perl bioperl"
short="Bioperl"
descr="Bioperl"
cmd="perl src/bioperl/DNAtranslate.pl"
runtest
pkgs="python python-biopython"
short="Biopython"
descr="Biopython"
cmd="python src/biopython/DNAtranslate.py"
runtest
fi
pkgs="ruby1.9.1 libbio-ruby"
short="BioRuby"
scr="BioRuby"
cmd="ruby1.9.1 -I ~/opt/ruby/bioruby/lib/ src/bioruby/DNAtranslate.rb"
runtest
if false ; then
pkgs="r-base"
short="R+Biostrings"
descr=$short
cmd="./src/R/DNAtranslate_Biostrings.R"
runRtest
pkgs="r-base"
short="R+GeneR"
descr=$short
cmd="./src/R/DNAtranslate_GeneR.R"
runRtest
pkgs=""
short="BioJava"
descr="BioJava+BioScala"
cmd="./src/biojava/scala/DNAtranslate"
# runtest - broken now
pkgs=""
short="Jython+BioJava"
descr="BioJava+jython"
cd src/biojava/jython
cmd="./DNAtranslate"
runtest
cd ../../..
pkgs=""
short="Jruby+BioJava"
descr="BioJava+jruby"
cd src/biojava/jruby
cmd="./DNAtranslate.rb"
runtest
cd ../../..
pkgs="ant"
short="Java special"
descr="Java2"
cd src/biojava/java
ant jar  
for jar in $(find ./dist -name '*.jar'); do
  CLASSPATH=$jar:$CLASSPATH
done
export CLASSPATH
cmd="java -Xms128M -Xmx384M javaa.Main -v"
runtest
cd ../../..
pkgs=""
short="biolib+ruby"
descr="Ruby+BigBio+Biolib/EMBOSS"
cd src/biolib/ruby
cmd="./DNAtranslate.rb"
runtest
cd ../../..
pkgs=""
short="biolib+python"
descr="Python+BioPython+Biolib/EMBOSS"
cd src/biolib/python
cmd="./DNAtranslate_EMBOSS.py"
runtest
cd ../../..
pkgs="python"
short="Python-FFI"
descr="Python-FFI"
cd src/python-ffi
cmd="python DNAtranslate.py"
runtest
cd ../../
pkgs="ruby"
short="Ruby-FFI"
descr="Ruby-FFI"
cd src/ruby-ffi
cmd="ruby DNAtranslate.rb"
runtest
cd ../../

fi

echo "Done."
