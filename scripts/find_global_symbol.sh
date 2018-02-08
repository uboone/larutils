#! /bin/sh

#    Find global symbol.

#    Contact    R. Hatcher
#               N. West

#    Invocation:-
#    ==========

#    find_global_symbol.sh options symbol.  See help message below for details.


#    Specification:-
#    =============

#    o    Search through all .so files in all directories defined
#         in LD_LIBRARY path for supplied symbol.

#    o    If located, attempt to demangle or mangle as appropriate..

#    Program Notes:-
#    =============

#    None.

symbol=""
all_libs=0
demangled=0
frag_search=0
print_types=0
verbose=0
textonly=1
print_help=0
for arg; do
  case $arg in
  -a) all_libs=1;;
  -d) demangled=1;;
  -f) frag_search=1;;
  -t) print_types=1;;
  -v) let verbose=${verbose}+1;;
  -u) textonly=0;;   # show U undefined as well (other than T W V )
  -h) print_help=1;;
   *) symbol="$arg"
  esac
done

sysname=`uname -s`

  if [ $print_types = 1 ] ; then
  echo ' '
  echo 'For Linux:'
  echo '   Symbol types are a single character from the following list:-'
  echo ' '
  echo '      A '
  echo '           The symbols value is absolute, and will not be changed by'
  echo '           further linking.'
  echo ' '
  echo '      B '
  echo '           The symbol is in the uninitialized data section (known as'
  echo '           BSS).'
  echo ' '
  echo '      C '
  echo '           The symbol is common.  Common symbols are uninitialized data.'
  echo '           When linking, multiple common symbols may appear with the'
  echo '           same name.  If the symbol is defined anywhere, the common'
  echo '           symbols are treated as undefined references.  For more'
  echo '           details on common symbols, see the discussion of -warn-common'
  echo '           in *Note Linker options: (ld.info)Options.'
  echo '           details on common symbols, see the discussion of -warn-common'
  echo '           in *Note Linker options: (ld.info)Options.'
  echo ' '
  echo '      D '
  echo '           The symbol is in the initialized data section.'
  echo ' '
  echo '      G '
  echo '           The symbol is in an initialized data section for small'
  echo '           objects.  Some object file formats permit more efficient'
  echo '           access to small data objects, such as a global int variable'
  echo '           as opposed to a large global array.'
  echo ' '
  echo '      I '
  echo '           The symbol is an indirect reference to another symbol.  This'
  echo '           is a GNU extension to the a.out object file format which is'
  echo '           rarely used.'
  echo ' '
  echo '      N '
  echo '           The symbol is a debugging symbol.'
  echo ' '
  echo '      R '
  echo '           The symbol is in a read only data section.'
  echo ' '
  echo '      S '
  echo '           The symbol is in an uninitialized data section for small'
  echo '           objects.'
  echo ' '
  echo '      T '
  echo '           The symbol is in the text (code) section.'
  echo ' '
  echo '      U '
  echo '           The symbol is undefined.'
  echo ' '
  echo '      V '
  echo '           The symbol is a weak object.  When a weak defined symbol is'
  echo '           linked with a normal defined symbol, the normal defined'
  echo '           symbol is used with no error.  When a weak undefined symbol'
  echo '           is linked and the symbol is not defined, the value of the'
  echo '           weak symbol becomes zero with no error.'
  echo ' '
  echo '      W '
  echo '           The symbol is a weak symbol that has not been specifically'
  echo '           tagged as a weak object symbol.  When a weak defined symbol'
  echo '           is linked with a normal defined symbol, the normal defined'
  echo '           symbol is used with no error.  When a weak undefined symbol'
  echo '           is linked and the symbol is not defined, the value of the'
  echo '           weak symbol becomes zero with no error.'
  echo ' '
  echo '      - '
  echo '           The symbol is a stabs symbol in an a.out object file.  In'
  echo '           this case, the next values printed are the stabs other field,'
  echo '           the stabs desc field, and the stab type.  Stabs symbols are'
  echo '           used to hold debugging information.  For more information,'
  echo '           see *Note Stabs: (stabs.info)Top.'
  echo ' '
  echo '      ? '
  echo '           The symbol type is unknown, or object file format specific.'
  echo ' '
  echo 'For Mac OS X:'
  echo '   U (undefined)'
  echo '   A (absolute)'
  echo '   T (text section symbol)'
  echo '   D (data section symbol)'
  echo '   B (bss section symbol)'
  echo '   C (common symbol)'
  echo '   - (for debugger  symbol  table  entries; see -a below)'
  echo '   S (symbol in a section other than those above), or'
  echo '   I (indirect symbol).'
  echo "  If the symbol is local (non-external), the symbol's type is instead"
  echo '  represented by the corresponding lowercase letter.  A lower case u'
  echo '  in a dynamic shared library indicates a undefined reference to a'
  echo '   private external in  another module in the same library.'
  exit 0
fi

if [ "$symbol" = "" -o $print_help -ne 0 ] ; then
  echo "  find_global_symbol finds mangled or demangled symbols in libraries"
  echo "  within LD_LIBRARY_PATH.  Invocation:-"
  echo ""
  echo "     find_global_symbol.sh options name"
  echo ""
  echo "   where options are none or more of the following:-"
  echo ""
  echo "   -a    All libs: search all libs."
  echo "         Default:  exclude /usr/lib"
  echo ""
  echo "   -d    Demangled: Force name to be treated as demangled"
  echo "         Default:  treat name as mangled unless it contains a ("
  echo ""
  echo "   -f    Fragment search: name is a fragment, match any symbol that"
  echo "         contains name."
  echo "         Default:  symbol must exactly match name."
  echo ""
  echo "   -u    Print all references, including undefined symbols."
  echo "         Default:  only print symbol types T, W or V"
  echo ""
  echo "   -v    Increase verbosity."
  echo "         -v prints each directory path as searched."
  echo "         -v -v for debugging."
  echo ""
  echo "   -t    Print list of symbol types (may not exactly match nm)"
  echo ""
  echo "   -h    Print this help message."
  echo ""
  exit 0;
fi

#  Escape puntuation characters.
search_string=`echo $symbol | awk                           \
   '{ ORS="";                                               \
      loc=1;                                                \
      while (loc <= length($0)) {                           \
        c = substr($0,loc,1);                               \
        if ( c < "0" || c == "[" || c == "]") print "\\\\"; \
        print c;                                            \
        loc++;                                              \
      }                                                     \
    } ' `
if [ $frag_search -eq 0 ] ; then search_string=" $search_string\$"; fi

#  Set demangle flag.
if [ $demangled -eq 0 ]; then
  demangled=`echo $symbol | awk '{ print index($0,"(") }'`
fi
if [ $demangled -eq 0 ]; then demangled=""; fi

if [ $sysname == "Darwin" ]; then
   #DEMANGLEFLG="--defined-only -g"
   DEMANGLEFLG="-g"

else
   DEMANGLEFLG=
   NODEMANGLE=""
fi

if [ $demangled ]
then
  echo "Searching for demangled symbol '$symbol'"
  case $sysname in
     Darwin ) transform1="c++filt"
              transform2="tr x x"
              opt1="-g"
              opt2="-g"
              ;;
     * ) transform1="tr x x"   # no-op pass through
         transform2="tr x x"
         opt1="--demangle"
         opt2=""
         ;;
  esac
else
  #opt1=""
  #opt2="${DEMANGLEFLG}"
  echo "Searching for mangled symbol '$symbol'"
  case $sysname in
     Darwin ) transform1="tr x x"
              transform2="c++filt"
              opt1="-g"
              opt2="-g"
              ;;
     * ) transform1="tr x x"   # no-op pass through
         transform2="tr x x"
         opt1=""
         opt2="--demangle"
         ;;
  esac
fi

list=`echo ${LD_LIBRARY_PATH}:${DYLD_LIBRARY_PATH} | \
                              awk ' { num_elem = split($1,list,":"); \
                                      i_elem = 1;                    \
                                      while (i_elem <= num_elem) {   \
                                        print list[i_elem];          \
                                        i_elem++;                    \
                                      }                              \
                                    }  '`

tried=":"
for path in $list
do
# Skip unwanted directories.
  if [    "$path" = "."         \
       -o ! -d $path  ]; then  echo "Skipping $path"; continue; fi
  if [  $all_libs -eq 0 -a "$path" = "/usr/lib" ]; then echo "Skipping $path"; continue; fi

# Skip duplicates
  tried_before=`echo $tried :$path: | awk ' { print index($1,$2) }'`
  if [ $tried_before -ne 0 ]; then continue; fi
  tried=$tried$path:

  cd $path
  if [ $verbose -gt 0 ]; then
    echo "Checking libraries in $path..."
  fi

  for file in `ls -1 *.so *.dylib 2>/dev/null`
  do
     # echo "nm $opt1 $file | $tranform1 | egrep -n \"$search_string\""
     resultmulti=`nm $opt1 $file | $transform1 | egrep -n "$search_string"`

    printpath=0
    if [ "$resultmulti"  != "" ]
    then
       if [ $verbose -gt 1 ]; then
          echo "-->>> start resultmulti"
          echo "$resultmulti"
          echo "--<<<   end resultmulti"
      fi
      while read -r result; do
         if [ $textonly -ne 0 ]; then
            # S = Mac OS X "other section" (where typeinfo might be found)
            nmatch=`echo $result | egrep -c -v ' U ' `
            if [ $nmatch -eq 0 ]; then continue; fi
         fi
         if [ $verbose -eq 0 -a $printpath -eq 0 ]; then
            echo "Found in path $path/..."
            printpath=1
         fi

         echo "    Found in $file"
         echo "        Entry: $result"
         line=`echo $result | awk ' { loc = index($1,":");\
                                    print substr($1,1,loc-1) }'`
         if [ $verbose -gt 1 ]; then
            echo "awk returned $line"
         fi
         result=`nm $opt2 $file | $transform2 | head -$line | tail -1`
         echo "        Translates to $result"
      done <<< "$resultmulti"
    fi
  done
done

echo ""
echo "Note that  U       <symbol>    means the symbol is undefined (required) here"
echo "           T, W, V <symbol>    is defined here"
echo ""
echo "For a full list of codes type"
echo ""
echo "    find_global_symbol.sh -h"
echo ""

exit 0;

