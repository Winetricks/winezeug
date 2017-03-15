#!/usr/bin/env python2
# coding=utf-8
"""Check the spec files from Wine"""

import argparse
import fnmatch
import os
import re
import shutil
import subprocess
import sys

__copyright__ = "Copyright 2017, André Hentschel"

def spec_arg_to_val(spec_args, pedantic):
    """Converts from spec arg to a value which is used to call the function under test"""
    spec_args = spec_args.strip().replace("  ", " ").replace(" ", ", ")
    spec_args = spec_args.replace("long", "100")
    spec_args = spec_args.replace("int64", "(FILETIME)MAXLONGLONG")
    spec_args = spec_args.replace("int128", '(D3DXCOLOR)"0123456789abcdef"')
    spec_args = spec_args.replace("word", "100")
    spec_args = spec_args.replace("s_word", "-57005")
    spec_args = spec_args.replace("float", "5.4321")
    spec_args = spec_args.replace("double", "5.43212345")
    spec_args = spec_args.replace("segptr", "100")
    spec_args = spec_args.replace("segstr", "100")
    spec_args = spec_args.replace("wstr", '(WCHAR*)"w"')
    spec_args = spec_args.replace("str", '(CHAR*)"PSTR"')
    if pedantic:
        spec_args = spec_args.replace("ptr", "100")
    else:
        spec_args = spec_args.replace("ptr", "(void*)0xdeadbeef")
    return spec_args

def find_file_with_function(function, parentsrc, arch):
    """Try to place the test function in the same file as the function under test"""
    match_count = 0
    match_fname = ""
    archs = ["_arm.c", "_arm64.c", "_i386.c", "_powerpc.c", "_x86_64.c"]
    archs_filtered = tuple([a for a in archs if a != arch])
    for fname in fnmatch.filter(os.listdir("."), "*.c"):
        if fname.endswith(archs_filtered):
            continue
        with open(fname) as cfile:
            lastline = ""
            for line in cfile:
                abis = ("API", "CALLBACK", "RPC_USER", "RPC_STUB", "_ENTRY")
                if any(abi in line for abi in abis):
                    if ";" in line and "}" not in line:
                        continue
                    if re.search(r"(?:" + "|".join(abis) + r").*\s" + function + r"\s*\(", line):
                        #print 'in %s:\t%s' %(fname, line.strip())
                        match_count += 1
                        match_fname = fname
                elif not match_count and function in line and any(abi in lastline for abi in abis):
                    if re.search(function + r"\s*\(", line):
                        match_fname = fname
                if function + "_tester(void) {" in line:
                    #print "already done: %s" %function
                    cfile.close()
                    return None
                lastline = line
            cfile.close()

    if len(match_fname) > 1:
        return match_fname
    elif not parentsrc:
        print "Sorry, didn't found %s" %function
    return None

def add_function(specl, parentsrc, arch, pedantic):
    """Parse a spec entry and add a test function to a C file if appropriate"""
    if specl.strip().startswith("#"):
        return
    rgx = re.search(r"stdcall\s+(.*)\((.*)\)(.*)", specl)
    proto_fun = rgx.group(1).rsplit(None, 1)[-1] # get the last word, ignoring flags
    proto_arg = rgx.group(2)
    if len(rgx.group(3)) > 0 and not rgx.group(3).strip().startswith("#"):
        proto_fun = rgx.group(3).strip()

    if "." in proto_fun: #skipping forward
        return

    if "#" in proto_fun:
        proto_fun = proto_fun.split("#")[0].strip()

    proto_arg = spec_arg_to_val(proto_arg, pedantic)
    match_fname = find_file_with_function(proto_fun, parentsrc, arch)
    if not match_fname:
        return

    new = open(match_fname, "a")
    new.write("void " + proto_fun + "_tester(void) {" + proto_fun + "(" + proto_arg + ");}\n")
    new.close()

def fix_spec(spec, func, argn, styp):
    """This fixes a spec entry with given arg number and new arg type"""
    print func + " Nr. " + str(argn) + " -> " + styp
    spec_tmp = spec + ".bu"
    shutil.copy(spec, spec_tmp)
    old = open(spec_tmp, "r")
    new = open(spec, "w")
    for line in old:
        if " stdcall" in line and func in line:
            rgx = re.search(r"stdcall\s+(.*)\((.*)\)(.*)", line)
            specl_fun = rgx.group(1).rsplit(None, 1)[-1] # get last word to skip flags
            specl_arg = rgx.group(2)
            if len(rgx.group(3)) > 0 and specl_fun != func:
                specl_fun = rgx.group(3).strip()
            if "." in specl_fun or specl_fun != func:
                new.write(line)
                continue
            args = specl_arg.strip().split(" ")
            args[argn - 1] = styp
            new.write(line.replace(specl_arg, " ".join(args).strip()))
        else:
            new.write(line)
    new.close()
    old.close()
    os.remove(spec_tmp)

def guess_styp(exp, typ):
    """Guess arg type based on expected and actual type"""
    styp = "long"
    if "int" in typ:
        styp = "ptr"
    if exp.find("}") > 0 and exp[exp.index("}") - 1] == "*":
        styp = "ptr"
    if "CSTR" in exp or "const CHAR * " in exp:
        styp = "str"
    elif "CWSTR" in exp or "const WCHAR * " in exp:
        styp = "wstr"
    return styp

def parse_make_output(spec):
    """Extract the correct spec arg type from compiler output"""
    argn = 0
    func = ""
    styp = "ERR"
    txtfile = open("spec.txt", "r")
    for line in txtfile:
        if "error:" in line:
            print line.strip()
        if "warning: passing argument" in line: # gcc only
            argn = 0
            func = ""
            styp = "ERR"
            rgx = re.search(r"passing argument ([0-9]*)", line)
            if rgx:
                argn = int(rgx.group(1))
        elif "_tester" in line:
            func = ""
            rgx = re.search(r"void (.*)_tester", line)
            if rgx:
                func = rgx.group(1)
        elif "note: expected" in line: # gcc only
            rgx = re.search(r"note: expected (.*) but argument is of type (.*)", line)
            if rgx:
                styp = guess_styp(rgx.group(1), rgx.group(2))
        if argn > 0 and len(func) > 1 and styp != "ERR":
            fix_spec(spec, func, argn, styp)
            argn = 0
            func = ""
            styp = "ERR"
    txtfile.close()

def read_dir(name, arch, pedantic):
    """Apply the winespec magic to a given source folder"""
    prevdir = os.getcwd()
    os.chdir(name)
    parentsrc = False
    try:
        makefile = open("Makefile.in", "r")
        for line in makefile:
            if "PARENTSRC" in line:
                parentsrc = True
                break
        makefile.close()
    except IOError:
        pass
    try:
        spec = name + ".spec"
        if os.path.isfile(spec):
            specfile = open(spec, "r")
            for line in specfile:
                if " stdcall" in line:
                    add_function(line, parentsrc, arch, pedantic)
            specfile.close()
        # expected..H is for HMODULE HWND HINF HKEY HINSTANCE and such
        subprocess.Popen("make -C ../" + os.path.join(ARGS.builddir[0], name) + " 2>&1 | "
                         "grep -v -e HANDLE "
                         "-e DEVINST -e cl_ "
                         "-e 'note: expected..SQLH' -e 'note: expected..H' "
                         "| grep note -A1 -B3 > spec.txt", shell=True).wait()
        if os.stat("spec.txt").st_size == 0:
            os.remove("spec.txt")
        else:
            parse_make_output(name + ".spec")
    except IOError:
        print "Failed in " + name
    finally:
        subprocess.Popen("git checkout -f *.c 2> /dev/null", shell=True).wait()
        os.chdir(prevdir)

PARSER = argparse.ArgumentParser(description='Check the spec files from Wine',
                                 epilog='Save your work before running the script.'
                                 'You will most likely want to run it in the dlls/ folder')
PARSER.add_argument('--pedantic', help='Extensive checking for all pointers')
PARSER.add_argument('--builddir', nargs=1, help='e.g. ../../wine32/dlls', required=True)
PARSER.add_argument('--arch', nargs=1, choices=['arm', 'arm64', 'i386', 'powerpc', 'x86_64'],
                    help='which architecture is the builddir?', required=True)
PARSER.add_argument('folder', nargs='?', help='a single folder e.g. ntdll')

ARGS = PARSER.parse_args()

try:
    subprocess.check_call("git diff-index --quiet HEAD --", shell=True)
except subprocess.CalledProcessError:
    print "You need to be in a Git repository without uncommitted changes"
    sys.exit(1)

if ARGS.folder:
    DNAME = ARGS.folder.replace(".spec", "").rstrip('/')
    read_dir(DNAME, "_" + ARGS.arch[0] + ".c", ARGS.pedantic)
else:
    for DNAME in os.listdir("."):
        if os.path.isdir(DNAME):
            print "\t\t\t" + DNAME
            read_dir(DNAME, "_" + ARGS.arch[0] + ".c", ARGS.pedantic)
