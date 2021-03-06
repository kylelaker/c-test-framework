#!/bin/bash

source project.include

# detect timeout script
TIMEOUT="timeout"
$TIMEOUT --help &>/dev/null
if [[ $? -ne 0 ]]; then
    TIMEOUT="gtimeout"
fi

# initialize grade counts
acount=0
bcount=0
ccount=0
dcount=0
fcount=0
xcount=0

# all students
for eid in `ls $SUBMIT`; do

    # print student id
    printf '%15s ' "$eid"

    # clear old results
    runpath="$RESULTS/$eid"
    rm -rf "$runpath"

    # check for submission
    if [ -e "$SUBMIT/$eid/$TAG" ]; then

        # create testing folder for this student
        mkdir -p "$runpath"

        # check and copy all files
        ok="yes"
        for f in $FILES; do
            if [ ! -e "$SUBMIT/$eid/$TAG/$f" ]; then
                ok="no"
            else
                cp -H "$SUBMIT/$eid/$TAG/$f" "$runpath/$f"
            fi
        done

        # save timestamp
        tstamp=$(ls -l $SUBMIT/$eid/$TAG/*.c | head -n 1 | tr -s ' ' | cut -d ' ' -f 6-8)

        # check for completeness
        if [ "$ok" == "yes" ]; then

            # copy other files
            for f in $REFFILES; do
                cp -RL "$REF/$f" "$runpath/$f"
            done

            # clean project to remove any old object files from reference
            make -C "$runpath" clean &>/dev/null

            # compile project
            make -C "$runpath" &>"$runpath/build.txt"

            # run tests
            $TIMEOUT 2m make -C "$runpath" test &>"$runpath/summary.txt"

            # check for compilation errors
            if [ -e "$runpath/$EXE" ]; then

                # summarize unit test results
                uresults="Unit results: $(grep Checks "$runpath/tests/utests.txt")"
                if [ -z "$(grep "D_" "$runpath/tests/utests.txt")" ]; then
                    if [ -z "$(grep "C_" "$runpath/tests/utests.txt")" ]; then
                        if [ -z "$(grep "B_" "$runpath/tests/utests.txt")" ]; then
                            if [ -z "$(grep "A_" "$runpath/tests/utests.txt")" ]; then
                                ugrade="A"
                            else
                                ugrade="B"
                            fi
                        else
                            ugrade="C"
                        fi
                    else
                        ugrade="D"
                    fi
                else
                    ugrade="F"
                fi

                # summarize integration test results
                iresults="Integration failures: $(grep FAIL "$runpath/tests/itests.txt" | grep -v X_ | wc -l)"
                if [ -z "$(grep "D_.*FAIL" "$runpath/tests/itests.txt")" ]; then
                    if [ -z "$(grep "C_.*FAIL" "$runpath/tests/itests.txt")" ]; then
                        if [ -z "$(grep "B_.*FAIL" "$runpath/tests/itests.txt")" ]; then
                            if [ -z "$(grep "A_.*FAIL" "$runpath/tests/itests.txt")" ]; then
                                igrade="A"
                            else
                                igrade="B"
                            fi
                        else
                            igrade="C"
                        fi
                    else
                        igrade="D"
                    fi
                else
                    igrade="F"
                fi

                # calculate base grade
                if [ "$ugrade" \< "$igrade" ]; then
                    bgrade=$igrade
                else
                    bgrade=$ugrade
                fi

                # update grade counts
                if [ "$bgrade" == "A" ]; then
                    acount=$((acount+1))
                elif [ "$bgrade" == "B" ]; then
                    bcount=$((bcount+1))
                elif [ "$bgrade" == "C" ]; then
                    ccount=$((ccount+1))
                elif [ "$bgrade" == "D" ]; then
                    dcount=$((dcount+1))
                elif [ "$bgrade" == "F" ]; then
                    fcount=$((fcount+1))
                fi

                # get valgrind, compiler, and security check results
                vresults="$(grep "emory leak" "$runpath/tests/itests.txt")"
                cresults="$(grep -E "( warning:)|( error:)" "$runpath/build.txt")"
                sresults="$(grep -E "(atoi)|(atol)|(atoll)|(atof)|([^f]gets)|(strcat)|(strcpy)|(sprintf)" $runpath/*.c)"
                if [ -n "$cresults" ]; then
                    echo "Compiler warning/error(s):" >>"$runpath/summary.txt"
                    cat "$runpath/build.txt" >>"$runpath/summary.txt"
                fi
                if [ -n "$sresults" ]; then
                    echo "Insecure function check results:" >>"$runpath/summary.txt"
                    echo "$sresults" >>"$runpath/summary.txt"
                fi

                # print per-student summary
                printf ' %s  %12s  %-55s %-30s %s' "$ugrade $igrade $bgrade" "$tstamp" "$uresults" "$iresults" "$vresults"
                [ -n "$cresults" ] && printf ' Compiler warning/error(s).'
                [ -n "$sresults" ] && printf ' Insecure function(s).'
                echo ""

            else
                fcount=$((fcount+1))
                echo "     F  (does not compile)"
            fi
        else
            fcount=$((fcount+1))
            echo "     F  (incomplete submission)"
        fi
    else
        xcount=$((xcount+1))
        echo "     X  (no submission)"
    fi
done

# print overall summary
echo ""
echo "Grade summary:"
echo "  A $acount"
echo "  B $bcount"
echo "  C $ccount"
echo "  D $dcount"
echo "  F $fcount"
echo "  X $xcount"
echo ""

