!{\src2tex{textfont=tt}}
!!****m* ABINIT/m_geometry
!! NAME
!!  m_geometry
!!
!! FUNCTION
!!  This module contains basic tools to operate on vectors expressed in reduced coordinates.
!!
!! COPYRIGHT
!! Copyright (C) 2008-2012 ABINIT group (MG)
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

MODULE m_geometry

 use m_profiling

 use defs_basis
 use m_errors

 implicit none

 private

 public :: normv           ! Norm of vector(s) in reduced coordinates either in real or reciprocal space. 
 public :: vdotw           ! Scalar product between two reduced vectors either in real or reciprocal space.
 public :: wigner_seitz    ! Find the grid of points falling inside the Wigner-Seitz cell.

 interface normv
  module procedure normv_rdp_vector
  module procedure normv_int_vector
  !module procedure normv_int_vector_array  ! WARNING for the time being, do not use these 2 procedures,
  !module procedure normv_rdp_vector_array  ! sunstudio12 is not able to resolve which sub should be called.
 end interface normv

 interface vdotw
  module procedure vdotw_rr_vector
  module procedure vdotw_rc_vector
 end interface vdotw

CONTAINS  !===========================================================
!!***

!!****f* m_geometry/normv_rdp_vector
!! NAME
!! normv_rdp_vector
!!
!! FUNCTION
!! Compute the norm of a vector expressed in reduced coordinates using the metric met.
!! The result is multiplied by 2pi in case of a vector in reciprocal space
!! to take into account the correct normalisation of the reciprocal lattice vectors
!!
!! INPUTS
!!  xv(3)=Vector in reduced coordinates
!!  met(3,3)=Metric tensor
!!  space=Character defining whether we are working in real (r|R) or reciprocal space (g|G)
!!
!! OUTPUT
!!  normv_rdp_vector=norm of xv 
!!
!! NOTES
!!  The routine is able to deal both with a single vector as well as arrays of vectors.
!!  Versions for integer and real vectors are provided. 
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

function normv_rdp_vector(xv,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'normv_rdp_vector'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 real(dp) :: res
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3),xv(3)

! *************************************************************************

 res =  (xv(1)*met(1,1)*xv(1) + xv(2)*met(2,2)*xv(2) + xv(3)*met(3,3)*xv(3)  &
&  +two*(xv(1)*met(1,2)*xv(2) + xv(1)*met(1,3)*xv(3) + xv(2)*met(2,3)*xv(3)) )

 select case (space) 
 case ('r','R')
   res=SQRT(res)
 case ('g','G')
   res=two_pi*SQRT(res)
 case default
   MSG_BUG('Wrong value for space')
 end select
 
end function normv_rdp_vector
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/normv_int_vector
!! NAME
!!  normv_int_vector
!!
!! FUNCTION
!!  Returns the norm of an integer 3D vector expressed in reduced coordinates.
!!  either in real or reciprocal space. In the later case the factor 2pi has 
!!  to be included, due to the conventions used in abinit to define the reciprocal lattice. 
!!
!! INPUTS
!!
!! OUTPUT
!!
!! SOURCE

function normv_int_vector(xv,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'normv_int_vector'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 real(dp) :: res
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3) 
 integer,intent(in) :: xv(3)

! *************************************************************************

 res =  ( xv(1)*met(1,1)*xv(1) + xv(2)*met(2,2)*xv(2) + xv(3)*met(3,3)*xv(3)  &
&  +two*( xv(1)*met(1,2)*xv(2) + xv(1)*met(1,3)*xv(3) + xv(2)*met(2,3)*xv(3)) )

 select case (space) 
 case ('r','R')
   res=SQRT(res)
 case ('g','G')
   res=two_pi*SQRT(res)
 case default
   MSG_BUG('Wrong value for space')
 end select
 
end function normv_int_vector
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/normv_int_vector_array
!! NAME
!!  normv_int_vector_array
!!
!! FUNCTION
!!  Returns the norm of an array of integer 3D vectors expressed in reduced coordinates.
!!  either in real or reciprocal space. In the later case the factor 2pi has 
!!  to be included, due to the conventions used in abinit to define the reciprocal lattice. 
!!
!! INPUTS
!!
!! OUTPUT
!!
!! SOURCE

function normv_int_vector_array(xv,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'normv_int_vector_array'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3) 
 integer,intent(in) :: xv(:,:)
 !this awful trick is needed to avoid problems with abilint
 real(dp) :: res(SIZE(xv(1,:)))
 !real(dp) :: res(SIZE(xv,DIM=2))

! *************************************************************************

 res(:) = ( xv(1,:)*met(1,1)*xv(1,:) + xv(2,:)*met(2,2)*xv(2,:) + xv(3,:)*met(3,3)*xv(3,:)  &
&     +two*(xv(1,:)*met(1,2)*xv(2,:) + xv(1,:)*met(1,3)*xv(3,:) + xv(2,:)*met(2,3)*xv(3,:)) )

 select case (space) 
 case ('r','R')
   res(:)=SQRT(res(:))
 case ('g','G')
   res(:)=two_pi*SQRT(res(:))
 case default
   MSG_BUG('Wrong value for space')
 end select
 
end function normv_int_vector_array
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/normv_rdp_vector_array
!! NAME
!!  normv_rdp_vector_array
!!
!! FUNCTION
!!  Returns the norm of an array of real 3D vectors expressed in reduced coordinates.
!!  either in real or reciprocal space. In the later case the factor 2pi has 
!!  to be included, due to the conventions used in abinit to define the reciprocal lattice. 
!!
!! INPUTS
!!
!! OUTPUT
!!
!! SOURCE

function normv_rdp_vector_array(xv,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'normv_rdp_vector_array'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3) 
 real(dp),intent(in) :: xv(:,:)
 !this awful trick is needed to avoid problems with abilint
 real(dp) :: res(SIZE(xv(1,:)))
 !real(dp) :: res(SIZE(xv,DIM=2))

! *************************************************************************

 res(:) = ( xv(1,:)*met(1,1)*xv(1,:) + xv(2,:)*met(2,2)*xv(2,:) + xv(3,:)*met(3,3)*xv(3,:)  &
&     +two*(xv(1,:)*met(1,2)*xv(2,:) + xv(1,:)*met(1,3)*xv(3,:) + xv(2,:)*met(2,3)*xv(3,:)) )

 select case (space) 
 case ('r','R')
   res(:)=SQRT(res(:))
 case ('g','G')
   res(:)=two_pi*SQRT(res)
 case default
   MSG_BUG('Wrong value for space')
 end select
 
end function normv_rdp_vector_array
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/vdotw_rr_vector
!! NAME
!! vdotw_rr_vector
!!
!! FUNCTION
!! Compute the scalar product between two vectors expressed in reduced coordinates
!! The result is multiplied by (2pi)**2 in case of vectors in reciprocal space
!! to take into account the correct normalisation of the reciprocal lattice vectors
!!
!! INPUTS
!!  xv(3),xw(3)=Vectors in reduced coordinates
!!  met(3,3)=Metric tensor
!!  space=Character defining whether we are working in real (r) or reciprocal space (g)
!!
!! OUTPUT
!!  res=scalar product of xv and xw  
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

function vdotw_rr_vector(xv,xw,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'vdotw_rr_vector'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 real(dp) :: res
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3),xv(3),xw(3)

! *************************************************************************
 
 res = (  met(1,1)* xv(1)*xw(1)                &
&        +met(2,2)* xv(2)*xw(2)                &
&        +met(3,3)* xv(3)*xw(3)                &
&        +met(1,2)*(xv(1)*xw(2) + xv(2)*xw(1)) &
&        +met(1,3)*(xv(1)*xw(3) + xv(3)*xw(1)) &
&        +met(2,3)*(xv(2)*xw(3) + xv(3)*xw(2)) ) 

 select case (space)
 case ('r','R')
   return 
 case ('g','G')
   res= res * (two_pi**2)
 case default
   MSG_BUG('Wrong value for space')
 end select

end function vdotw_rr_vector
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/vdotw_rc_vector
!! NAME
!! vdotw_rc_vector
!!
!! FUNCTION
!! Compute the scalar product between two vectors expressed in reduced coordinates
!! First vector is real, the second one is complex.
!! The result is multiplied by (2pi)**2 in case of vectors in reciprocal space
!! to take into account the correct normalisation of the reciprocal lattice vectors
!!
!! INPUTS
!!  xv(3),xw(3)=Vectors in reduced coordinates
!!  met(3,3)=Metric tensor
!!  space=Character defining whether we are working in real (r) or reciprocal space (g)
!!
!! OUTPUT
!!  res=complex scalar product of xv and xw  
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

function vdotw_rc_vector(xv,xw,met,space) result(res)


!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'vdotw_rc_vector'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 complex(dpc) :: res
 character(len=1),intent(in) :: space
!arrays
 real(dp),intent(in) :: met(3,3),xv(3) 
 complex(dpc),intent(in) :: xw(3)

! *************************************************************************
 
 res = (  met(1,1)* xv(1)*xw(1)                &
&        +met(2,2)* xv(2)*xw(2)                &
&        +met(3,3)* xv(3)*xw(3)                &
&        +met(1,2)*(xv(1)*xw(2) + xv(2)*xw(1)) &
&        +met(1,3)*(xv(1)*xw(3) + xv(3)*xw(1)) &
&        +met(2,3)*(xv(2)*xw(3) + xv(3)*xw(2)) ) 

 select case (space)
 case ('r','R')
   return 
 case ('g','G')
   res= res * (two_pi**2)
 case default
   MSG_BUG('Wrong value for space')
 end select

end function vdotw_rc_vector
!!***

!----------------------------------------------------------------------

!!****f* m_geometry/wigner_seitz
!! NAME
!! wigner_seitz
!!
!! FUNCTION
!! Calculates a grid of points that falls inside of (and eventually on the surface of) 
!! the Wigner-Seitz supercell centered on the origin of the B lattice with primitive 
!! translations nmonkh(1)*a_1+nmonkh(2)*a_2+nmonkh(3)*a_3.
!! Subroutine taken from the Wannier90 code. Modified by MG to fulfil abinit coding rules. 
!! API slightly changed the wrt wannier90 version.
!!
!! COPYRIGHT
!! Copyright (C) 2007 Jonathan Yates, Arash Mostofi,         
!! Young-Su Lee, Nicola Marzari, Ivo Souza, David Vanderbilt.
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!!
!! INPUTS
!!  center(3)=The Wigner-Seitz cell is centered on this point in reduced coordinates.
!!  rmet(3,3)=Real space metric ($\textrm{bohr}^{2}$).
!!  kptrlatt(3)=Values defining the supercell.
!!  prtvol=If different from 0 print out the points falling inside the W-S cell and the correponding weights.
!!  lmax(3)=see Notes below.
!!
!! OUTPUT
!!  npts=number of points falling inside the Wigner-Seitz cell
!!  irvec(3,npts)=Reduced coordinated of the points inside the W-S cell
!!  ndegen(npts)=Weigths associated to each point.
!!
!! SIDE EFFECTS
!!  In input irvec and ndegen are NULL pointers. They are allocated with the correct
!!  size inside the routine and returned to the caller.
!!
!! NOTES
!! The Wannier functions live in a supercell of the real space unit cell.
!! This supercell is mp_grid unit cells long in each direction
!! The algorithm loops over grid points r on a unit cell that is 8 times larger than this
!! primitive supercell. 
!! One of these points is in the W-S cell if it is closer to center(:) 
!! than any of the other points R where R are the translation vectors of the supercell.
!! In the end npts contains the total number of grid points that have been found in the Wigner-Seitz cell
!! The number of lattice vectors R along each direction of the supercell is defined by lmax.
!!
!! PARENTS
!!      m_wannier2abinit
!!
!! CHILDREN
!!      wrtout
!!
!! SOURCE

subroutine wigner_seitz(center,lmax,kptrlatt,rmet,npts,irvec,ndegen,prtvol)
    
 use defs_basis

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'wigner_seitz'
 use interfaces_14_hidewrite
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 integer,optional,intent(in) :: prtvol
 integer,intent(out) :: npts 
!arrays
 integer,intent(in) :: kptrlatt(3,3),lmax(3)
 integer,pointer :: irvec(:,:),ndegen(:)
 real(dp),intent(in) :: center(3),rmet(3,3)

!Local variables-------------------------------
!scalars
 integer :: in1,in2,in3,l1,l2,l3,ii,icount,n1,n2,n3
 integer :: l0,l1_max,l2_max,l3_max,nl,verbose,mm1,mm2,mm3
 real(dp) :: tot,dist_min
 real(dp),parameter :: TOL_DIST=tol6
 character(len=500) :: msg    
!arrays
 real(dp) :: diff(3)
 real(dp),allocatable :: dist(:)
 real(dp),allocatable :: swap2(:,:),swap1(:)
 
! *************************************************************************

 verbose=0; if (PRESENT(prtvol)) verbose=prtvol

 if (kptrlatt(1,2)/=0 .or. kptrlatt(2,1)/=0 .or. &
&    kptrlatt(1,3)/=0 .or. kptrlatt(3,1)/=0 .or. &
&    kptrlatt(2,3)/=0 .or. kptrlatt(3,2)/=0 ) then 
   MSG_ERROR('Off-diagonal elements of kptrlatt must be zero')
 end if 

 n1=kptrlatt(1,1)
 n2=kptrlatt(2,2)
 n3=kptrlatt(3,3)

 l1_max=lmax(1) 
 l2_max=lmax(2) 
 l3_max=lmax(3) 
 
 nl=(2*l1_max+1)*(2*l2_max+1)*(2*l3_max+1)
 l0=1+l1_max*(1+(2*l2_max+1)**2+(2*l3_max+1)) ! Index of the origin.
 ABI_ALLOCATE(dist,(nl))

 ! Allocate with maximum size
 mm1=2*n1+1
 mm2=2*n2+1
 mm3=2*n3+1
 ABI_ALLOCATE(irvec,(3,mm1*mm2*mm3))
 ABI_ALLOCATE(ndegen,(mm1*mm2*mm3))

 npts=0  
 do in1=-n1,n1
   do in2=-n2,n2
     do in3=-n3,n3
      !
      ! Loop over the nl points R. R=0 corresponds to l1=l2=l3=1, or icount=l0
      icount=0  
      do l1=-l1_max,l1_max 
        do l2=-l2_max,l2_max
          do l3=-l3_max,l3_max  
            ! * Calculate |r-R-r_0|^2.
            diff(1)= in1 -l1*n1 -center(1)
            diff(2)= in2 -l2*n2 -center(2)
            diff(3)= in3 -l3*n3 -center(3)
            icount=icount+1  
            dist(icount)=DOT_PRODUCT(diff,MATMUL(rmet,diff))
          end do
        end do
      end do

      dist_min=MINVAL(dist)

      if (ABS(dist(l0)-dist_min)<TOL_DIST) then
        npts=npts+1  
        ndegen(npts)=0
        do ii=1,nl
          if (ABS(dist(ii)-dist_min)<TOL_DIST) ndegen(npts)=ndegen(npts)+1
        end do
        irvec(1,npts)=in1  
        irvec(2,npts)=in2   
        irvec(3,npts)=in3   
      end if
     end do !in3
   end do !in2
 end do !in1

 if (verbose>=1) then
   write(msg,'(a,i4)')' lattice points in Wigner-Seitz supercell: ',npts
   call wrtout(std_out,msg,'COLL') 
   do ii=1,npts
     write(msg,'(a,3(i3),a,i4)')'  vector ', irvec(:,ii),' degeneracy: ', ndegen(ii)
     call wrtout(std_out,msg,'COLL') 
   end do
 end if

 ! === Check the "sum rule" ===
 tot=zero 
 do ii=1,npts  
   tot=tot+one/ndegen(ii)
 end do
 if (ABS(tot-(n1*n2*n3))>tol8) then
   write(msg,'(a,es16.8,a,i5)')'Something wrong in the generation of the mesh ',tot,' /= ',n1*n2*n3
   MSG_ERROR(msg)
 end if

 ABI_DEALLOCATE(dist)

 ! === Reallocate the output with correct size ===
 ABI_ALLOCATE(swap1,(npts))
 swap1(:)=ndegen(1:npts)
 ABI_DEALLOCATE(ndegen)
 ABI_ALLOCATE(ndegen,(npts))
 ndegen=swap1
 ABI_DEALLOCATE(swap1)

 ABI_ALLOCATE(swap2,(3,npts))
 swap2(:,:)=irvec(1:3,1:npts)
 ABI_DEALLOCATE(irvec)
 ABI_ALLOCATE(irvec,(3,npts))
 irvec=swap2
 ABI_DEALLOCATE(swap2)

end subroutine wigner_seitz
!!***

!----------------------------------------------------------------------

END MODULE m_geometry
!!***
