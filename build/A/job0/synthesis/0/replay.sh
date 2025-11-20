#!/usr/bin/env bash
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    echo "${BASH_SOURCE[0]} must be executed."
    return
fi

# Parse replay arguments
CD_WORK="/sc_work/build/A/job0/synthesis/0"
PRINT=""
CMDPREFIX=""
SKIPEXPORT=0
DONODE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --which)
            PRINT="which"
            shift
            ;;
        --version)
            PRINT="version"
            shift
            ;;
        --directory)
            PRINT="directory"
            shift
            ;;
        --command)
            PRINT="command"
            shift
            ;;
        --skipcd)
            CD_WORK="."
            shift
            ;;
        --skipexports)
            SKIPEXPORT=1
            shift
            ;;
        --cmdprefix)
            CMDPREFIX="$2"
            shift
            shift
            ;;
        --node)
            DONODE=1
            shift
            shift
            ;;
        -h|--help)
            echo "Usage: $0"
            echo "  Options:"
            echo "    --which           print which executable would be used"
            echo "    --version         print the version of the executable, if supported"
            echo "    --directory       print the execution directory"
            echo "    --command         print the execution command"
            echo "    --skipcd          do not change directory into replay directory"
            echo "    --skipexports     do not export environmental variables"
            echo "    --cmdprefix <cmd> prefix to add to the replay command, such as dgb"
            echo "    --node            execute entire node"
            echo "    -h,--help         print this help"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

if [ $SKIPEXPORT == 0 ]; then
    # Environmental variables
    export PATH="/venv/bin:/sc_tools/bin:/sc_tools/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    export LD_LIBRARY_PATH="/sc_tools/lib:/sc_tools/lib64"
fi

# Switch to the working directory
cd "$CD_WORK"

case $PRINT in
    "which")
        which yosys
        exit 0
        ;;
    "version")
        yosys --version
        exit 0
        ;;
    "directory")
        echo "Working directory: $PWD"
        exit 0
        ;;
    "command")
        echo "yosys -c /venv/lib/python3.10/site-packages/siliconcompiler/tools/yosys/scripts/sc_synth_asic.tcl"
        exit 0
        ;;
esac

if [ $DONODE == 1 ]; then
python3 -m siliconcompiler.scheduler.run_node \
    -cfg "inputs/A.pkg.json" \
    -builddir "${PWD}/../../../../" \
    -step "synthesis" \
    -index "0" \
    -cwd "$PWD" \
    -replay
else
# Command execution
$CMDPREFIX \
yosys \
  -c \
  /venv/lib/python3.10/site-packages/siliconcompiler/tools/yosys/scripts/sc_synth_asic.tcl
fi
