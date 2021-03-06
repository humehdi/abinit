!{\src2tex{textfont=tt}}
!!****f* ABINIT/calc_vhxc_me
!! NAME
!!  calc_vhxc_me
!!
!! FUNCTION
!!  Evaluate the matrix elements of $v_H$ and $v_{xc}$ and $v_U$
!!  both in case of NC pseudopotentials and PAW (LDA+U, presently, is only available in PAW)
!!  The matrix elements of $v_{xc}$ are calculated with and without the core contribution.
!!  The later quantity is required in case of GW calculations.
!!
!! COPYRIGHT
!!  Copyright (C) 2008-2012 ABINIT group (MG)
!!  This file is distributed under the terms of the
!!  GNU General Public License, see ~abinit/COPYING
!!  or http://www.gnu.org/copyleft/gpl.txt .
!!
!! INPUTS
!!  Mflags
!!  gsqcutf_eff=Fourier cutoff on G^2 for "large sphere" of radius double
!!   that of the basis sphere--appropriate for charge density rho(G),Hartree potential, and pseudopotentials
!!  Dtset <type(dataset_type)>=all input variables in this dataset
!!  ngfftf(18)contain all needed information about 3D fine FFT, see ~abinit/doc/input_variables/vargs.htm#ngfft
!!  nfftf=number of points in the fine FFT mesh (for this processor)
!!  Pawtab(Dtset%ntypat*Dtset%usepaw) <type(pawtab_type)>=paw tabulated starting data
!!  Paw_an(natom) <type(paw_an_type)>=paw arrays given on angular mesh
!!  Pawang <type(pawang_type)>=paw angular mesh and related data
!!  Paw_ij(natom) <type(paw_ij_type)>=paw arrays given on (i,j) channels
!!  Pawfgrtab(natom) <type(pawfgrtab_type)>=atomic data given on fine rectangular grid
!!  Cryst<Crystal_structure>=unit cell and symmetries
!!     %natom=number of atoms in the unit cell
!!     %rprimd(3,3)=direct lattice vectors
!!     %ucvol=unit cell volume
!!     %ntypat= number of type of atoms
!!     %typat(natom)=type of each atom
!!  vhartr(nfftf)= Hartree potential in real space on the fine FFT mesh
!!  vxc(nfftf,nspden)= xc potential in real space on the fine FFT grid
!!  Wfd <type (wfs_descriptor)>=Structure gathering information on the wavefunctions.
!!  rhor(nfftf,nspden)=density in real space (smooth part if PAW).
!!  rhog(2,nfftf)=density in reciprocal space (smooth part if PAW).
!!  nhatgrdim= -PAW only- 0 if nhatgr array is not used ; 1 otherwise
!!  usexcnhat= -PAW only- 1 if nhat density has to be taken into account in Vxc
!!  kstab(2,Wfd%nkibz,Wfd%nsppol)=Table temporary used to be compatible with the old implementation.
!!
!! OUTPUT
!!  Mels
!!   %vxc   =matrix elements of $v_{xc}[nv+nc]$.
!!   %vxcval=matrix elements of $v_{xc}[nv]$.
!!   %vhartr=matrix elements of $v_H$.
!!   %vu    =matrix elements of $v_U$.
!!
!! SIDE EFFECTS
!!  Paw_ij= In case of self-Consistency it is changed. It will contain the new H0
!!  Hamiltonian calculated using the QP densities. The valence contribution to XC
!!  is removed.
!!
!! NOTES
!!  All the quantities ($v_H$, $v_{xc}$ and $\psi$ are evaluated on the "fine" FFT mesh.
!!  In case of calculations with pseudopotials the usual mesh is defined by ecut.
!!  For PAW calculations the dense FFT grid defined bt ecutdg is used
!!  Besides, in case of PAW, the matrix elements of V_hartree do not contain the onsite
!!  contributions due to the coulombian potentials generate by ncore and tncore.
!!  These quantities, as well as the onsite kinetic terms, are stored in Paw_ij%dij0.
!!
!! PARENTS
!!      sigma
!!
!! CHILDREN
!!      cprj_alloc,cprj_free,herm_melements,init_melements,initmpi_seq,mkkin
!!      paw_mknewh0,rhohxc,wfd_change_ngfft,wfd_distribute_bbp,wfd_get_cprj
!!      wfd_get_ur,wrtout,xsum_melements
!!
!! SOURCE


#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"

subroutine calc_vhxc_me(Wfd,Mflags,Mels,Cryst,Dtset,gsqcutf_eff,nfftf,ngfftf,&
&  vtrial,vhartr,vxc,Psps,Pawtab,Paw_an,Pawang,Pawfgrtab,Paw_ij,dijexc_core,&
&  rhor,rhog,usexcnhat,nhat,nhatgr,nhatgrdim,kstab,&
&  taug,taur) ! optional arguments

 use defs_basis
 use defs_datatypes
 use defs_abitypes
 use m_profiling
 use m_errors

 use m_blas,        only : xdotc
 use m_wfs,         only : wfd_get_ur, wfs_descriptor, wfd_distribute_bbp, wfd_get_cprj, wfd_change_ngfft
 use m_crystal,     only : crystal_structure
 use m_melemts,     only : init_melements, herm_melements, xsum_melements, melements_flags_type, melements_type

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'calc_vhxc_me'
 use interfaces_14_hidewrite
 use interfaces_44_abitypes_defs
 use interfaces_51_manage_mpi
 use interfaces_56_recipspace
 use interfaces_56_xc
 use interfaces_66_paw
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: nhatgrdim,usexcnhat,nfftf
 real(dp),intent(in) :: gsqcutf_eff
 type(Dataset_type),intent(in) :: Dtset
 type(Pseudopotential_type),intent(in) :: Psps
 type(wfs_descriptor),intent(inout) :: Wfd
 type(Pawang_type),intent(in) :: Pawang
 type(Crystal_structure),intent(in) :: Cryst
 type(melements_flags_type),intent(in) :: Mflags
 type(melements_type),intent(out) :: Mels
!arrays
 integer,intent(in) :: ngfftf(18)
 integer,intent(in) :: kstab(2,Wfd%nkibz,Wfd%nsppol)
 real(dp),intent(in) :: vhartr(nfftf),vxc(nfftf,Wfd%nspden),vtrial(nfftf,Wfd%nspden)
 real(dp),intent(in) :: rhor(nfftf,Wfd%nspden),rhog(2,nfftf)
 real(dp),intent(in) :: nhat(nfftf,Wfd%nspden*Wfd%usepaw)
 real(dp),intent(in) :: nhatgr(nfftf,Wfd%nspden,3*nhatgrdim)
 real(dp),intent(in),optional :: taur(nfftf,Wfd%nspden*Dtset%usekden),taug(2,nfftf*Dtset%usekden)
 !real(dp),intent(in) :: dijexc_core(cplex_dij*lmn2_size_max,ndij,Cryst%ntypat)
 real(dp),intent(in) :: dijexc_core(:,:,:)
 type(Pawtab_type),intent(in) :: Pawtab(Cryst%ntypat*Wfd%usepaw)
 type(Paw_an_type),intent(in) :: Paw_an(Cryst%natom)
 type(Paw_ij_type),intent(inout) :: Paw_ij(Cryst%natom)
 type(Pawfgrtab_type),intent(inout) :: Pawfgrtab(Cryst%natom)

!Local variables-------------------------------
!scalars
 integer :: iat,ikc,ik_ibz,ib,jb,is,b_start,b_stop
 integer :: itypat,lmn_size,j0lmn,jlmn,ilmn,klmn,klmn1,lmn2_size_max
 integer :: isppol,izero,cplex_dij,npw_k
 integer :: nspinor,nsppol,nspden,nk_calc
 integer :: rank,comm,master,nprocs
 integer :: isp1,isp2,iab,nsploop,nkxc,option,n3xccc_,nk3xc,my_nbbp,my_nmels
 real(dp) :: nfftfm1,fact,DijH,enxc_val,vxcval_avg,h0dij,vxc1,vxc1_val,re_p,im_p,dijsigcx
 logical :: ltest
 character(len=500) :: msg
 type(MPI_type) :: MPI_enreg_seq
!arrays
 integer,parameter :: spinor_idxs(2,4)=RESHAPE((/1,1,2,2,1,2,2,1/),(/2,4/))
 integer,pointer :: kg_k(:,:)
 integer :: got(Wfd%nproc)
 integer,allocatable :: kcalc2ibz(:)
 integer,allocatable :: dimlmn(:)
 integer,allocatable :: bbp_ks_distrb(:,:,:,:)
 real(dp) :: tmp_xc(2,Wfd%nspinor**2),tmp_xcval(2,Wfd%nspinor**2)
 real(dp) :: tmp_H(2,Wfd%nspinor**2),tmp_U(2,Wfd%nspinor**2)
 real(dp) :: tmp_h0ij(2,Wfd%nspinor**2),tmp_sigcx(2,Wfd%nspinor**2)
 real(dp) :: dijU(2),strsxc(6),kpt(3),vxc1ab(2),vxc1ab_val(2)
 real(dp),allocatable :: kxc_(:,:),vh_(:),xccc3d_(:),vxc_val(:,:)
 real(dp),allocatable :: kinpw(:),veffh0(:,:)
 complex(dpc) :: tmp(3)
 complex(gwpc),pointer :: ur1_up(:),ur1_dwn(:)
 complex(gwpc),pointer :: ur2_up(:),ur2_dwn(:)
 complex(gwpc),pointer :: cg1(:),cg2(:)
 complex(gwpc),target,allocatable :: ur1(:),ur2(:)
 complex(dpc),allocatable :: vxcab(:),vxcab_val(:),u1cjg_u2dpc(:),kinwf2(:),veffh0_ab(:)
 logical :: bbp_mask(Wfd%mband,Wfd%mband)
 type(Cprj_type),allocatable ::  Cprj_b1ks(:,:),Cprj_b2ks(:,:)

! *************************************************************************

 DBG_ENTER("COLL")

 ! Usually FFT meshes for wavefunctions and potentials are not equal. Two approaches are possible:
 ! Either we Fourier interpolate potentials on the coarse WF mesh or we FFT the wfs on the dense mesh.
 ! The later approach is used, more CPU demanding but more accurate.
 if ( ANY(ngfftf(1:3) /= Wfd%ngfft(1:3)) ) call wfd_change_ngfft(Wfd,Cryst,Psps,ngfftf)

 comm   = Wfd%comm
 rank   = Wfd%my_rank
 master = Wfd%master
 nprocs = Wfd%nproc

 ! * Fake MPI_type for sequential part
 call initmpi_seq(MPI_enreg_seq)

 nspinor=Wfd%nspinor
 nsppol =Wfd%nsppol
 nspden =Wfd%nspden
 ABI_CHECK(nspinor==1,"Remember to ADD SO")
 !
 !    TODO not used for the time being but it should be a standard input of the routine.
 !  bbks_mask(Wfd%mband,Wfd%mband,Wfd%nkibz,Wfd%nsppol)=Logical mask used to select
 !    the matrix elements to be calculated.
 ABI_ALLOCATE(kcalc2ibz,(Wfd%nkibz))
 kcalc2ibz=0
 !
 ! === Index in the IBZ of the GW k-points ===
 ! * Only these points will be considered.
 nk_calc=0
 do ik_ibz=1,Wfd%nkibz
   if ( ALL(kstab(1,ik_ibz,:)/=0) .and. ALL(kstab(2,ik_ibz,:)/=0) ) then
     nk_calc=nk_calc+1
     kcalc2ibz(nk_calc) = ik_ibz
   end if
 end do

 call init_melements(Mels,Mflags,nsppol,nspden,Wfd%nspinor,Wfd%nkibz,Wfd%kibz,kstab)

 if (Mflags%has_lexexch==1) then
   MSG_ERROR("Local EXX not coded!")
 end if
 !
 ! === Evaluate $v_\xc$ using only the valence charge ====
 msg = ' calc_vhxc_braket : calculating v_xc[n_val] (excluding non-linear core corrections) '
 call wrtout(std_out,msg,'COLL')

 do isppol=1,nsppol
   write(msg,'(a,i2,a,e16.6)')&
&    ' For spin ',isppol,' Min density rhor = ',MINVAL(rhor(:,isppol))
   call wrtout(std_out,msg,'COLL')
   if (Wfd%usepaw==1) then
     write(msg,'(a,i2,a,e16.6)')&
&      ' For spin ',isppol,' Min density nhat = ',MINVAL(nhat(:,isppol))
     call wrtout(std_out,msg,'COLL')
     write(msg,'(a,i2,a,e16.6)')&
&      ' For spin ',isppol,' Min density trho-nhat = ',MINVAL(rhor(:,isppol)-nhat(:,isppol))
     call wrtout(std_out,msg,'COLL')
     write(msg,'(a,i2)')' using usexcnhat = ',usexcnhat
     call wrtout(std_out,msg,'COLL')
   end if
 end do

 option = 0 ! Only exc, vxc, strsxc
 nkxc   = 0 ! No computation of XC kernel
 n3xccc_= 0 ! No core
 nk3xc  = 0 ! k3xc not needed
 izero  = Wfd%usepaw

 ABI_ALLOCATE(xccc3d_,(n3xccc_))
 ABI_ALLOCATE(vh_,(nfftf))
 ABI_ALLOCATE(kxc_,(nfftf,nkxc))
 ABI_ALLOCATE(vxc_val,(nfftf,nspden))

 call rhohxc(Dtset,enxc_val,gsqcutf_eff,izero,kxc_,MPI_enreg_seq,nfftf,ngfftf,&
& nhat,Wfd%usepaw,nhatgr,nhatgrdim,nkxc,nk3xc,nspden,n3xccc_,option,rhog,rhor,Cryst%rprimd,&
& strsxc,usexcnhat,vh_,vxc_val,vxcval_avg,xccc3d_,taug=taug,taur=taur)

 ABI_DEALLOCATE(xccc3d_)
 ABI_DEALLOCATE(vh_)
 ABI_DEALLOCATE(kxc_)

 write(msg,'(a,f8.4,2a,f8.4,a)')&
&  ' E_xc[n_val]  = ',enxc_val,  ' [Ha]. ',&
&  '<V_xc[n_val]> = ',vxcval_avg,' [Ha]. '
 call wrtout(std_out,msg,'COLL')

 ! === If PAW and qp-SCGW then update Paw_ij and calculate the matrix elements ===
 ! * We cannot simply rely on gwcalctyp because I need KS vxc in sigma.
 if (Wfd%usepaw==1.and.Mflags%has_hbare==1) then
   ABI_CHECK(Mflags%only_diago==0,"Wrong only_diago")

   call paw_mknewh0(nsppol,nspden,nfftf,Dtset%pawspnorb,Dtset%pawprtvol,Cryst,Psps,&
&    Pawtab,Paw_an,Paw_ij,Pawang,Pawfgrtab,vxc,vxc_val,vtrial)

   ! * Effective potential of the bare Hamiltonian: valence term is subtracted.
   ABI_ALLOCATE(veffh0,(nfftf,nspden))
   veffh0=vtrial-vxc_val
   !veffh0=vtrial !this is to retrieve the KS Hamiltonian
 end if

 ! === Setup of the hermitian operator vxcab ===
 ! * if nspden==4 vxc contains (v^11, v^22, Re[V^12], Im[V^12].
 ! * Cannot use directly Re and Im since we also need off-diagonal elements.
 if (nspinor==2) then
   ABI_ALLOCATE(vxcab,(nfftf))
   ABI_ALLOCATE(vxcab_val,(nfftf))
   vxcab    (:)=DCMPLX(vxc    (:,3),vxc    (:,4))
   vxcab_val(:)=DCMPLX(vxc_val(:,3),vxc_val(:,4))
   if (Mflags%has_hbare==1) then
     ABI_ALLOCATE(veffh0_ab,(nfftf))
     veffh0_ab(:)=DCMPLX(veffh0(:,3),veffh0(:,4))
   end if
 end if
 !
 ! === Allocate matrix elements of vxc[n], vxc_val[n_v], vH and vU ===
 ! * hbareme contains the matrix element of the new bare Hamiltonian h0.
 !if (Mflags%has_hbare==1) then
 !  allocate(kinpw(Wfd%npwwfn),kinwf2(Wfd%npwwfn*nspinor))
 !end if

 ABI_ALLOCATE(ur1,(nspinor*nfftf))
 ABI_ALLOCATE(ur2,(nspinor*nfftf))
 ABI_ALLOCATE(u1cjg_u2dpc,(nfftf))

 ! === Create distribution table for tasks ===
 ! * This section is parallelized inside MPI_COMM_WORLD
 !   as all processors are calling the routine with all GW wavefunctions

 ! TODO the table can be calculated at each (k,s) to save some memory.
 got=0; my_nmels=0
 ABI_ALLOCATE(bbp_ks_distrb,(Wfd%mband,Wfd%mband,nk_calc,nsppol))
 do is=1,nsppol
   do ikc=1,nk_calc
     ik_ibz=kcalc2ibz(ikc)
     bbp_mask=.FALSE.
     b_start=kstab(1,ik_ibz,is)
     b_stop =kstab(2,ik_ibz,is)
     if (Mflags%only_diago==1) then
       !do jb=b1,b2
       do jb=b_start,b_stop
         bbp_mask(jb,jb)=.TRUE.
       end do
     else
       bbp_mask(b_start:b_stop,b_start:b_stop)=.TRUE.
     end if

     call wfd_distribute_bbp(Wfd,ik_ibz,is,"Upper",my_nbbp,bbp_ks_distrb(:,:,ikc,is),got,bbp_mask)
     my_nmels = my_nmels + my_nbbp
   end do
 end do

 write(msg,'(a,i0,a)')" Will calculate ",my_nmels," <b,k,s|O|b',k,s> matrix elements in calc_vhxc_me."
 call wrtout(std_out,msg,'PERS')
 !
 ! =====================================
 ! ==== Loop over required k-points ====
 ! =====================================
 nfftfm1=one/nfftf

 do is=1,nsppol
   if (ALL(bbp_ks_distrb(:,:,:,is)/=rank)) CYCLE

   do ikc=1,nk_calc
     if (ALL(bbp_ks_distrb(:,:,ikc,is)/=rank)) CYCLE

     ik_ibz=kcalc2ibz(ikc)
     b_start=kstab(1,ik_ibz,is)
     b_stop =kstab(2,ik_ibz,is)
     npw_k = Wfd%Kdata(ik_ibz)%npw
     kpt=Wfd%kibz(:,ik_ibz)
     kg_k => Wfd%kdata(ik_ibz)%kg_k

     ! Calculate |k+G|^2 needed by hbareme
     !FIXME Here I have a problem if I use ecutwfn there is a bug somewhere in setshell or invars2m!
     ! ecutwfn is slightly smaller than the max kinetic energy in gvec. The 0.1 pad should partially solve the problem
     if (Mflags%has_hbare==1) then
       ABI_ALLOCATE(kinpw,(npw_k))
       ABI_ALLOCATE(kinwf2,(npw_k*nspinor))
       call mkkin(Dtset%ecutwfn+0.1_dp,Dtset%ecutsm,Dtset%effmass,Cryst%gmet,kg_k,kinpw,kpt,Wfd%npwwfn)
       where (kinpw>HUGE(zero)*1.d-11)
         kinpw=zero
       end where
     end if

     !do jb=b1,b2
     do jb=b_start,b_stop
       if (ALL(bbp_ks_distrb(:,jb,ikc,is)/=rank)) CYCLE

       if (Mflags%has_hbare==1) then
         cg2 => Wfd%Wave(jb,ik_ibz,is)%ug  ! Wfd contains 1:nkptgw wave functions
         kinwf2(1:npw_k)=cg2(1:npw_k)*kinpw(:)
         if (nspinor==2) kinwf2(npw_k+1:)=cg2(npw_k+1:)*kinpw(:)
       end if

       call wfd_get_ur(Wfd,jb,ik_ibz,is,ur2)

       !do ib=b1,jb ! Upper triangle
       do ib=b_start,jb

         if (bbp_ks_distrb(ib,jb,ikc,is)/=rank) CYCLE

         ! * Off-diagonal elements only for QPSCGW.
         if (Mflags%only_diago==1.and.ib/=jb) CYCLE

         call wfd_get_ur(Wfd,ib,ik_ibz,is,ur1)

         u1cjg_u2dpc(1:nfftf)=CONJG(ur1(1:nfftf))*ur2(1:nfftf)

         if (Mflags%has_vxc==1)      &
&          Mels%vxc     (ib,jb,ik_ibz,is)=SUM(u1cjg_u2dpc(1:nfftf)*vxc    (1:nfftf,is))*nfftfm1

         if (Mflags%has_vxcval==1)   &
&          Mels%vxcval  (ib,jb,ik_ibz,is)=SUM(u1cjg_u2dpc(1:nfftf)*vxc_val(1:nfftf,is))*nfftfm1

         if (Mflags%has_vhartree==1) &
&          Mels%vhartree(ib,jb,ik_ibz,is)=SUM(u1cjg_u2dpc(1:nfftf)*vhartr (1:nfftf))   *nfftfm1

         if (Mflags%has_hbare==1) then
           cg1 => Wfd%Wave(ib,ik_ibz,is)%ug(1:npw_k)
           Mels%hbare(ib,jb,ik_ibz,is)=  &
&            DOT_PRODUCT(cg1,kinwf2(1:npw_k)) + SUM(u1cjg_u2dpc(1:nfftf)*veffh0(1:nfftf,is))*nfftfm1
!&            xdotc(Wfd%npwwfn,cg1(1:),1,kinwf2(1:),1) + SUM(u1cjg_u2dpc(1:nfftf)*veffh0(1:nfftf,is))*nfftfm1
         end if

         if (nspinor==2) then !Here I can skip 21 if ib==jb
           ur1_up  => ur1(1:nfftf)
           ur1_dwn => ur1(nfftf+1:2*nfftf)
           ur2_up  => ur2(1:nfftf)
           ur2_dwn => ur2(nfftf+1:2*nfftf)

           if (Mflags%has_hbare==1) then
             cg1 => Wfd%Wave(ib,ik_ibz,is)%ug(npw_k+1:)
             tmp(1)=SUM(CONJG(ur1_dwn)*veffh0(:,2)*ur2_dwn)*nfftfm1 + DOT_PRODUCT(cg1,kinwf2(npw_k+1:))
             tmp(2)=SUM(CONJG(ur1_dwn)*      veffh0_ab(:) *ur2_dwn)*nfftfm1
             tmp(3)=SUM(CONJG(ur1_dwn)*CONJG(veffh0_ab(:))*ur2_dwn)*nfftfm1
             Mels%hbare(ib,jb,ik_ibz,2:4)=tmp(:)
           end if

           if (Mflags%has_vxc==1) then
             tmp(1) = SUM(CONJG(ur1_dwn)*      vxc(:,2) *ur2_dwn)*nfftfm1
             tmp(2) = SUM(CONJG(ur1_up )*      vxcab(:) *ur2_dwn)*nfftfm1
             tmp(3) = SUM(CONJG(ur1_dwn)*CONJG(vxcab(:))*ur2_up )*nfftfm1
             Mels%vxc(ib,jb,ik_ibz,2:4)=tmp(:)
           end if

           if (Mflags%has_vxcval==1) then
             tmp(1) = SUM(CONJG(ur1_dwn)*      vxc_val(:,2) *ur2_dwn)*nfftfm1
             tmp(2) = SUM(CONJG(ur1_up )*      vxcab_val(:) *ur2_dwn)*nfftfm1
             tmp(3) = SUM(CONJG(ur1_dwn)*CONJG(vxcab_val(:))*ur2_up )*nfftfm1
             Mels%vxcval(ib,jb,ik_ibz,2:4)=tmp(:)
           end if

           if (Mflags%has_vhartree==1) then
             tmp(1) = SUM(CONJG(ur1_dwn)*vhartr(:)*ur2_dwn)*nfftfm1
             Mels%vhartree(ib,jb,ik_ibz,2  )=tmp(1)
             Mels%vhartree(ib,jb,ik_ibz,3:4)=czero
           end if

         end if !nspinor==2

       end do !ib
     end do !jb

     if (Mflags%has_hbare==1) then
       ABI_DEALLOCATE(kinpw)
       ABI_DEALLOCATE(kinwf2)
     end if

   end do !ikc
 end do !is

 ABI_DEALLOCATE(ur1)
 ABI_DEALLOCATE(ur2)
 ABI_DEALLOCATE(vxc_val)
 ABI_DEALLOCATE(u1cjg_u2dpc)
 if (nspinor==2)  then
   ABI_DEALLOCATE(vxcab)
   ABI_DEALLOCATE(vxcab_val)
 end if

 if (Mflags%has_hbare==1) then
   ABI_DEALLOCATE(veffh0)
   if (nspinor==2)  then
     ABI_DEALLOCATE(veffh0_ab)
   end if
 end if
 !
 ! ====================================
 ! ===== Additional terms for PAW =====
 ! ====================================
 if (Wfd%usepaw==1) then

   ! * Tests if needed pointers in Paw_ij are associated.
   ltest=(associated(Paw_ij(1)%dijxc).and.associated(Paw_ij(1)%dijxc_val))
   ABI_CHECK(ltest,"dijxc or dijxc_val not associated")

   !* For LDA+U
   do iat=1,Cryst%natom
     itypat=Cryst%typat(iat)
     if (Pawtab(itypat)%usepawu>0) then
       ltest=(associated(Paw_ij(iat)%dijU))
       ABI_CHECK(ltest,"LDA+U but dijU not associated")
     end if
   end do

   if (Dtset%pawspnorb>0) then
     ltest=(associated(Paw_ij(1)%dijso))
     ABI_CHECK(ltest,"dijso not associated")
   end if

   lmn2_size_max=MAXVAL(Pawtab(:)%lmn2_size)

   if (Mflags%has_sxcore==1) then
     if (     SIZE(dijexc_core,DIM=1) /= lmn2_size_max  &
&        .or. SIZE(dijexc_core,DIM=2) /= 1              &
&        .or. SIZE(dijexc_core,DIM=3) /= Cryst%ntypat ) then
       MSG_BUG("Wrong sizes in dijexc_core")
     end if
   end if

   nsploop=nspinor**2

   ! ====================================
   ! === Assemble PAW matrix elements ===
   ! ====================================
   ABI_ALLOCATE(dimlmn,(Cryst%natom))
   do iat=1,Cryst%natom
     dimlmn(iat)=Pawtab(Cryst%typat(iat))%lmn_size
   end do

   ABI_ALLOCATE(Cprj_b1ks,(Cryst%natom,nspinor))
   ABI_ALLOCATE(Cprj_b2ks,(Cryst%natom,nspinor))
   call cprj_alloc(Cprj_b1ks,0,dimlmn)
   call cprj_alloc(Cprj_b2ks,0,dimlmn)

   do is=1,nsppol
     if (ALL(bbp_ks_distrb(:,:,:,is)/=rank)) CYCLE

     ! === Loop over required k-points ===
     do ikc=1,nk_calc
       if (ALL(bbp_ks_distrb(:,:,ikc,is)/=rank)) CYCLE
       ik_ibz=kcalc2ibz(ikc)
       b_start=kstab(1,ik_ibz,is)
       b_stop =kstab(2,ik_ibz,is)

       !do jb=b1,b2
       do jb=b_start,b_stop
         if (ALL(bbp_ks_distrb(:,jb,ikc,is)/=rank)) CYCLE

         ! === Load projected wavefunctions for this k-point, spin and band ===
         ! * Cprj are unsorted, full correspondence with xred. See ctocprj.F90!!
         call wfd_get_cprj(Wfd,jb,ik_ibz,is,Cryst,Cprj_b2ks,sorted=.FALSE.)

         !do ib=b1,jb ! Upper triangle
         do ib=b_start,jb
           if (bbp_ks_distrb(ib,jb,ikc,is)/=rank) CYCLE

           ! * Off-diagonal elements only for QPSCGW.
           if (Mflags%only_diago==1.and.ib/=jb) CYCLE

           call wfd_get_cprj(Wfd,ib,ik_ibz,is,Cryst,Cprj_b1ks,sorted=.FALSE.)
           !
           ! === Get onsite matrix elements summing over atoms and channels ===
           ! * Spin is external and fixed (1,2) if collinear.
           ! * if noncollinear loop internally over the four components ab.
           tmp_xc   =zero
           tmp_xcval=zero
           tmp_H    =zero
           tmp_U    =zero
           tmp_h0ij =zero
           tmp_sigcx=zero

           do iat=1,Cryst%natom
             itypat   =Cryst%typat(iat)
             lmn_size =Pawtab(itypat)%lmn_size
             cplex_dij=Paw_ij(iat)%cplex_dij
             klmn1=1

             do jlmn=1,lmn_size
               j0lmn=jlmn*(jlmn-1)/2
               do ilmn=1,jlmn
                 klmn=j0lmn+ilmn
                 ! TODO Be careful, here I assume that the onsite terms ij are symmetric
                 ! should check the spin-orbit case!
                 fact=one ; if (ilmn==jlmn) fact=half

                 ! === Loop over four components if nspinor==2 ===
                 ! * If collinear nsploop==1
                 do iab=1,nsploop
                   isp1=spinor_idxs(1,iab)
                   isp2=spinor_idxs(2,iab)

                   re_p=  Cprj_b1ks(iat,isp1)%cp(1,ilmn) * Cprj_b2ks(iat,isp2)%cp(1,jlmn) &
&                        +Cprj_b1ks(iat,isp1)%cp(2,ilmn) * Cprj_b2ks(iat,isp2)%cp(2,jlmn) &
&                        +Cprj_b1ks(iat,isp1)%cp(1,jlmn) * Cprj_b2ks(iat,isp2)%cp(1,ilmn) &
&                        +Cprj_b1ks(iat,isp1)%cp(2,jlmn) * Cprj_b2ks(iat,isp2)%cp(2,ilmn)

                   im_p=  Cprj_b1ks(iat,isp1)%cp(1,ilmn) * Cprj_b2ks(iat,isp2)%cp(2,jlmn) &
&                        -Cprj_b1ks(iat,isp1)%cp(2,ilmn) * Cprj_b2ks(iat,isp2)%cp(1,jlmn) &
&                        +Cprj_b1ks(iat,isp1)%cp(1,jlmn) * Cprj_b2ks(iat,isp2)%cp(2,ilmn) &
&                        -Cprj_b1ks(iat,isp1)%cp(2,jlmn) * Cprj_b2ks(iat,isp2)%cp(1,ilmn)

                   ! ==================================================
                   ! === Load onsite matrix elements and accumulate ===
                   ! ==================================================
                   if (nspinor==1) then

                     if (Mflags%has_hbare==1) then ! * Get new dij of h0 and accumulate.
                       h0dij=Paw_ij(iat)%dij(klmn,is)
                       tmp_h0ij(1,iab)=tmp_h0ij(1,iab) + h0dij*re_p*fact
                       tmp_h0ij(2,iab)=tmp_h0ij(2,iab) + h0dij*im_p*fact
                     end if

                     if (Mflags%has_sxcore==1) then ! * Fock operator generated by core electrons.
                       dijsigcx = dijexc_core(klmn,1,itypat)
                       tmp_sigcx(1,iab)=tmp_sigcx(1,iab) + dijsigcx*re_p*fact
                       tmp_sigcx(2,iab)=tmp_sigcx(2,iab) + dijsigcx*im_p*fact
                     end if

                     if (Mflags%has_vxc==1) then ! * Accumulate vxc[n1+nc] + vxc[n1+tn+nc].
                       vxc1 = Paw_ij(iat)%dijxc(klmn,is)
                       tmp_xc(1,iab)=tmp_xc(1,iab) + vxc1*re_p*fact
                       tmp_xc(2,iab)=tmp_xc(2,iab) + vxc1*im_p*fact
                     end if

                     if (Mflags%has_vxcval==1) then ! * Accumulate valence-only XC.
                       vxc1_val=Paw_ij(iat)%dijxc_val(klmn,is)
                       tmp_xcval(1,1)=tmp_xcval(1,1) + vxc1_val*re_p*fact
                       tmp_xcval(2,1)=tmp_xcval(2,1) + vxc1_val*im_p*fact
                     end if

                     if (Mflags%has_vhartree==1) then ! * Accumulate Hartree term of the PAW Hamiltonian.
                       DijH=Paw_ij(iat)%dijhartree(klmn)
                       tmp_H(1,1)=tmp_H(1,1) + DijH*re_p*fact
                       tmp_H(2,1)=tmp_H(2,1) + DijH*im_p*fact
                     end if

                     ! * Accumulate U term of the PAW Hamiltonian (only onsite AE contribution)
                     if (Mflags%has_vu==1) then
                       if (Pawtab(itypat)%usepawu>0) then
                         dijU(1)=Paw_ij(iat)%dijU(klmn,is)
                         tmp_U(1,1)=tmp_U(1,1) + dijU(1)*re_p*fact
                         tmp_U(2,1)=tmp_U(2,1) + dijU(1)*im_p*fact
                       end if
                     end if

                   else ! Spinorial case ===

                     ! FIXME H0 + spinor not implemented
                     if (Mflags%has_hbare==1.or.Mflags%has_sxcore==1) then
                       MSG_ERROR("not implemented")
                     end if

                     if (Mflags%has_vxc==1) then ! * Accumulate vxc[n1+nc] + vxc[n1+tn+nc].
                       vxc1ab(1) = Paw_ij(iat)%dijxc(klmn1,  iab)
                       vxc1ab(2) = Paw_ij(iat)%dijxc(klmn1+1,iab)
                       tmp_xc(1,iab) = tmp_xc(1,iab) + (vxc1ab(1)*re_p - vxc1ab(2)*im_p)*fact
                       tmp_xc(2,iab) = tmp_xc(2,iab) + (vxc1ab(2)*re_p + vxc1ab(1)*im_p)*fact
                     end if

                     if (Mflags%has_vxcval==1) then ! * Accumulate valence-only XC.
                       vxc1ab_val(1) = Paw_ij(iat)%dijxc_val(klmn1,  iab)
                       vxc1ab_val(2) = Paw_ij(iat)%dijxc_val(klmn1+1,iab)
                       tmp_xcval(1,iab) = tmp_xcval(1,iab) + (vxc1ab_val(1)*re_p - vxc1ab_val(2)*im_p)*fact
                       tmp_xcval(2,iab) = tmp_xcval(2,iab) + (vxc1ab_val(2)*re_p + vxc1ab_val(1)*im_p)*fact
                     end if

                     ! * In GW, dijhartree is always real.
                     if (Mflags%has_vhartree==1) then ! * Accumulate Hartree term of the PAW Hamiltonian.
                       if (iab==1.or.iab==2) then
                         DijH = Paw_ij(iat)%dijhartree(klmn)
                         tmp_H(1,iab) = tmp_H(1,iab) + DijH*re_p*fact
                         tmp_H(2,iab) = tmp_H(2,iab) + DijH*im_p*fact
                       end if
                     end if

                     ! TODO "ADD LDA+U and SO"
                     ! check this part
                     if (Mflags%has_vu==1) then
                       if (Pawtab(itypat)%usepawu>0) then ! * Accumulate the U term of the PAW Hamiltonian (only onsite AE contribution)
                         dijU(1)=Paw_ij(iat)%dijU(klmn1  ,iab)
                         dijU(2)=Paw_ij(iat)%dijU(klmn1+1,iab)
                         tmp_U(1,iab) = tmp_U(1,iab) + (dijU(1)*re_p - dijU(2)*im_p)*fact
                         tmp_U(2,iab) = tmp_U(2,iab) + (dijU(2)*re_p + dijU(1)*im_p)*fact
                       end if
                     end if

                   end if
                 end do !iab

                 klmn1=klmn1+cplex_dij

               end do !ilmn
             end do !jlmn
           end do !iat
           !
           ! ========================================
           ! ==== Add to plane wave contribution ====
           ! ========================================
           if (nspinor==1) then

             if (Mflags%has_hbare==1)    &
&              Mels%hbare   (ib,jb,ik_ibz,is) = Mels%hbare   (ib,jb,ik_ibz,is) + DCMPLX(tmp_h0ij(1,1),tmp_h0ij(2,1))

             if (Mflags%has_vxc==1)      &
&              Mels%vxc     (ib,jb,ik_ibz,is) = Mels%vxc     (ib,jb,ik_ibz,is) + DCMPLX(tmp_xc(1,1),tmp_xc(2,1))

             if (Mflags%has_vxcval==1)   &
&              Mels%vxcval  (ib,jb,ik_ibz,is) = Mels%vxcval  (ib,jb,ik_ibz,is) + DCMPLX(tmp_xcval(1,1),tmp_xcval(2,1))

             if (Mflags%has_vhartree==1) &
&              Mels%vhartree(ib,jb,ik_ibz,is) = Mels%vhartree(ib,jb,ik_ibz,is) + DCMPLX(tmp_H (1,1),tmp_H (2,1))

             if (Mflags%has_vu==1)       &
&              Mels%vu      (ib,jb,ik_ibz,is) = DCMPLX(tmp_U(1,1),tmp_U(2,1))

             if (Mflags%has_sxcore==1)   &
&              Mels%sxcore  (ib,jb,ik_ibz,is) = DCMPLX(tmp_sigcx(1,1),tmp_sigcx(2,1))

           else

             if (Mflags%has_hbare==1)    &
&              Mels%hbare   (ib,jb,ik_ibz,:) = Mels%hbare(ib,jb,ik_ibz,:) + DCMPLX(tmp_h0ij(1,:),tmp_h0ij(2,:))

             if (Mflags%has_vxc==1)      &
&              Mels%vxc     (ib,jb,ik_ibz,:) = Mels%vxc   (ib,jb,ik_ibz,:) + DCMPLX(tmp_xc(1,:),tmp_xc(2,:))

             if (Mflags%has_vxcval==1)   &
&              Mels%vxcval  (ib,jb,ik_ibz,:) = Mels%vxcval(ib,jb,ik_ibz,:) + DCMPLX(tmp_xcval(1,:),tmp_xcval(2,:))

             if (Mflags%has_vhartree==1) &
&              Mels%vhartree(ib,jb,ik_ibz,:) = Mels%vhartree(ib,jb,ik_ibz,:) + DCMPLX(tmp_H (1,:),tmp_H (2,:))

             if (Mflags%has_vu==1)       &
&              Mels%vu      (ib,jb,ik_ibz,:) = DCMPLX(tmp_U(1,:),tmp_U(2,:))
           end if

         end do !ib
       end do !jb

     end do !is
   end do !ikc

   ABI_DEALLOCATE(dimlmn)
   call cprj_free(Cprj_b1ks)
   ABI_DEALLOCATE(Cprj_b1ks)
   call cprj_free(Cprj_b2ks)
   ABI_DEALLOCATE(Cprj_b2ks)
 end if !PAW

 ABI_DEALLOCATE(bbp_ks_distrb)

 ! === Sum up contributions on each node ===
 ! * Set the corresponding has_* flags to 2.
 call xsum_melements(Mels,comm)

 ! * Reconstruct lower triangle.
 call herm_melements(Mels)

 ABI_DEALLOCATE(kcalc2ibz)

 DBG_EXIT("COLL")

end subroutine calc_vhxc_me
!!***
