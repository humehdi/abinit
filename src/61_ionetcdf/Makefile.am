#
# Makefile for ABINIT                                      -*- Automake -*-
# Generated by make-makefiles-corelibs on 2012/04/11 04:16:05 +0000

#
# IMPORTANT NOTE
#
# Any manual change to this file will systematically be overwritten.
# Please modify the make-makefiles-corelibs script or its config file instead.
#

AM_CFLAGS = @ABI_CPPFLAGS@
AM_FCFLAGS = @FPPFLAGS@ @FCFLAGS_FREEFORM@ @FCFLAGS_MODDIR@ @fcflags_opt_61_ionetcdf@

INCLUDES = \
	@src_incs_incs@ \
	@fallbacks_incs@ \
	@lib_bigdft_incs@ \
	@lib_etsf_io_incs@ \
	@lib_netcdf_incs@

# Regular source files
lib61_ionetcdf_srcs = \
	ab_define_var.F90 \
	abi_etsf_init.F90 \
	abi_etsf_electrons_put.F90 \
	abi_etsf_geo_put.F90 \
	ini_wf_etsf.F90 \
	ini_wf_netcdf.F90 \
	m_abi_etsf.F90 \
	m_crystal_io.F90 \
	read_md_hist.F90 \
	write_md_hist.F90 \
	write_eig.F90 \
	wrt_moldyn_netcdf.F90 \
	interfaces_61_ionetcdf.F90

# Library description
noinst_LIBRARIES = lib61_ionetcdf.a

lib61_ionetcdf_a_SOURCES= $(lib61_ionetcdf_srcs)

CLEANFILES = \
	ab_define_var_cpp.f90 \
	abi_etsf_init_cpp.f90 \
	abi_etsf_electrons_put_cpp.f90 \
	abi_etsf_geo_put_cpp.f90 \
	ini_wf_etsf_cpp.f90 \
	ini_wf_netcdf_cpp.f90 \
	m_abi_etsf_cpp.f90 \
	m_crystal_io_cpp.f90 \
	read_md_hist_cpp.f90 \
	write_md_hist_cpp.f90 \
	write_eig_cpp.f90 \
	wrt_moldyn_netcdf_cpp.f90 \
	interfaces_61_ionetcdf_cpp.f90

EXTRA_DIST = abinit.src

EXTRA_DIST += abinit.dep

#Dependencies (inside the directory) of the directory ./src/61_ionetcdf
#
#COPYRIGHT
#Copyright (C) 2010-2011 ABINIT group
#This file is distributed under the terms of the
#GNU General Public License, see ~abinit/COPYING
#or http://www.gnu.org/copyleft/gpl.txt .
#
#THIS FILE IS GENERATED AUTOMATICALLY BY abilint.
#To do that: config/scripts/abilint --dependencies . .

CLEANFILES += \
	interfaces_61_ionetcdf.$(MODEXT) \
	m_abi_etsf.$(MODEXT) \
	m_crystal_io.$(MODEXT) 

abi_etsf_init.$(OBJEXT): interfaces_61_ionetcdf.$(OBJEXT) m_abi_etsf.$(OBJEXT) 

write_eig.$(OBJEXT): interfaces_61_ionetcdf.$(OBJEXT) 

write_md_hist.$(OBJEXT): interfaces_61_ionetcdf.$(OBJEXT) 

EXTRA_DIST += _61_ionetcdf_
