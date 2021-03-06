!{\src2tex{textfont=tt}}
!!****f* ABINIT/mklocl
!! NAME
!! mklocl
!!
!! FUNCTION
!! This method is a wrapper for mklocl_recipspace and mklocl_realspace.
!! It does some consistency checks before calling one of the two methods.
!!
!! Optionally compute :
!!  option=1 : local ionic potential throughout unit cell
!!  option=2 : contribution of local ionic potential to E gradient wrt xred
!!  option=3 : contribution of local ionic potential to
!!                stress tensor (only with reciprocal space computations)
!!  option=4 : contribution of local ionic potential to
!!                second derivative of E wrt xred  (only with reciprocal space computations)
!!
!! COPYRIGHT
!! Copyright (C) 1998-2012 ABINIT group (DCA, XG, GMR)
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!!
!! INPUTS
!!  if(option==3) eei=local pseudopotential part of total energy (hartree)
!!  gmet(3,3)=reciprocal space metric ($\textrm{Bohr}^{-2}$).
!!  gprimd(3,3)=reciprocal space dimensional primitive translations
!!  gsqcut=cutoff on $|G|^2$: see setup1 for definition (doubled sphere).
!!  mgfft=maximum size of 1D FFTs
!!  mpi_enreg=informations about MPI parallelization
!!  natom=number of atoms in unit cell.
!!  nattyp(ntypat)=number of atoms of each type in cell.
!!  nfft=(effective) number of FFT grid points (for this processor)
!!  ngfft(18)=contain all needed information about 3D FFT, see ~abinit/doc/input_variables/vargs.htm#ngfft
!!  nspden=number of spin-density components
!!  ntypat=number of types of atoms.
!!  option= (see above)
!!  ph1d(2,3*(2*mgfft+1)*natom)=1-dim structure factor phase information.
!!  psps <type(pseudopotential_type)>=variables related to pseudopotentials
!!  qprtrb(3)= integer wavevector of possible perturbing potential
!!   in basis of reciprocal lattice translations
!!  rhog(2,nfft)=electron density rho(G) (electrons/$\textrm{Bohr}^3$)
!!    (needed if option==2 or if option==4)
!!  rhor(nfft,nspden)=electron density in electrons/bohr**3.
!!    (needed if option==2 or if option==4)
!!  rprimd(3,3)=dimensional primitive translations in real space (bohr)
!!  ucvol=unit cell volume ($\textrm{Bohr}^3$).
!!  vprtrb(2)=complex amplitude of possible perturbing potential; if nonzero,
!!   perturbing potential is added of the form
!!   $V(G)=(vprtrb(1)+I*vprtrb(2))/2$ at the values G=qprtrb and
!!   $(vprtrb(1)-I*vprtrb(2))/2$ at $G=-qprtrb$ (integers)
!!  xred(3,natom)=reduced dimensionless atomic coordinates
!!
!! OUTPUT
!!  (if option==1) vpsp(nfft)=local crystal pseudopotential in real space.
!!  (if option==2) grtn(3,natom)=grads of Etot wrt tn.
!!  (if option==3) lpsstr(6)=components of local psp part of stress tensor
!!   (Cartesian coordinates, symmetric tensor) in hartree/$\textrm{bohr}^3$
!!   Store 6 unique components in order 11, 22, 33, 32, 31, 21
!!  (if option==4) dyfrlo(3,3,natom)=d2 Eei/d tn(i)/d tn(j).  (Hartrees)
!!
!! SIDE EFFECTS
!!
!! NOTES
!! Note that the present routine is tightly connected to the vloca3.f routine,
!! that compute the derivative of the local ionic potential
!! with respect to one atomic displacement. The argument list
!! and the internal loops to be considered were sufficiently different
!! as to make the two routine different.
!!
!! PARENTS
!!      forces,prcref,prcref_PMA,respfn,setvtr
!!
!! CHILDREN
!!      leave_new,mklocl_realspace,mklocl_recipspace,mklocl_wavelets,wrtout
!!      xredxcart
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

subroutine mklocl(dtset, dyfrlo,eei,gmet,gprimd,grtn,gsqcut,lpsstr,mgfft,&
&  mpi_enreg,natom,nattyp,nfft,ngfft,nspden,ntypat,option,ph1d,psps,qprtrb,&
&  rhog,rhor,rprimd,ucvol,vprtrb,vpsp,wvl,xred)

 use m_profiling

 use defs_basis
 use defs_datatypes
 use defs_abitypes
 use defs_wvltypes

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'mklocl'
 use interfaces_14_hidewrite
 use interfaces_16_hideleave
 use interfaces_42_geometry
 use interfaces_67_common, except_this_one => mklocl
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: mgfft,natom,nfft,nspden,ntypat,option
 real(dp),intent(in) :: eei,gsqcut,ucvol
 type(MPI_type),intent(inout) :: mpi_enreg
 type(dataset_type),intent(in) :: dtset
 type(pseudopotential_type),intent(in) :: psps
 type(wvl_internal_type), intent(in) :: wvl
!arrays
 integer,intent(in) :: nattyp(ntypat),ngfft(18),qprtrb(3)
 real(dp),intent(in) :: gmet(3,3),gprimd(3,3),ph1d(2,3*(2*mgfft+1)*natom)
 real(dp),intent(in) :: rhog(2,nfft),rhor(nfft,nspden),rprimd(3,3)
 real(dp),intent(in) :: vprtrb(2)
 real(dp),intent(inout) :: xred(3,natom)
 real(dp),intent(out) :: dyfrlo(3,3,natom),grtn(3,natom),lpsstr(6),vpsp(nfft)

!Local variables-------------------------------
!scalars
 character(len=500) :: message
!arrays
 real(dp),allocatable :: xcart(:,:)

! *************************************************************************

!DEBUG
!write(std_out,*)' mklocl : enter '
!ENDDEBUG

 if (option < 1 .or. option > 4) then
   write(message, '(a,a,a,a,i3,a,a)' ) ch10,&
&   ' mklocl : ERROR - ',ch10,&
&   '  From the calling routine, option=',option,ch10,&
&   '  The only allowed values are between 1 and 4.'
   call wrtout(std_out,message,'COLL')
   call leave_new('COLL')
 end if
 if (option > 2 .and. .not.psps%vlspl_recipSpace) then
   write(message, '(a,a,a,a,i3,a,a,a,a)' ) ch10,&
&   ' mklocl : ERROR - ',ch10,&
&   '  From the calling routine, option=',option,ch10,&
&   '  but the local part of the pseudo-potential is in real space.',ch10,&
&   '  Action : set icoulomb = 0 to turn-off real space computations.'
   call wrtout(std_out,message,'COLL')
   call leave_new('COLL')
 end if
 if (option > 2 .and. dtset%usewvl == 1) then
   write(message, '(a,a,a,a,i3,a,a)' ) ch10,&
&   ' mklocl : ERROR - ',ch10,&
&   '  From the calling routine, option=',option,ch10,&
&   '  but this is not implemented yet from wavelets.'
   call wrtout(std_out,message,'COLL')
   call leave_new('COLL')
 end if

 if (dtset%usewvl == 0) then
!  Plane wave case
   if (psps%vlspl_recipSpace) then

     call mklocl_recipspace(dyfrlo,eei,gmet,gprimd,grtn,gsqcut,lpsstr,mgfft, &
&     mpi_enreg,psps%mqgrid_vl,natom,nattyp,nfft,ngfft, &
&     ntypat,option,dtset%paral_kgb,ph1d,psps%qgrid_vl,qprtrb,rhog,ucvol, &
&     psps%vlspl,vprtrb,vpsp)
   else
     call mklocl_realspace(dtset, grtn, mpi_enreg, natom, nattyp, nfft, &
&     ngfft, nspden, ntypat, option, psps, rhog, rhor, &
&     rprimd, ucvol, vpsp, wvl, xred)
   end if
 else
!  Store xcart for each atom
   ABI_ALLOCATE(xcart,(3, dtset%natom))
   call xredxcart(dtset%natom, 1, rprimd, xcart, xred)
!  Wavelets case
   call mklocl_wavelets(dtset, grtn, mpi_enreg, option, rhor, rprimd, vpsp, wvl, xcart)
   ABI_DEALLOCATE(xcart)
 end if

end subroutine mklocl
!!***
