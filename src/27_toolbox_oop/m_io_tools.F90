!{\src2tex{textfont=tt}}
!!****m* ABINIT/m_io_tools
!! NAME
!!  m_io_tools
!!
!! FUNCTION
!!  This module contains basic tools to deal with Fortran IO
!!
!! COPYRIGHT
!! Copyright (C) 2008-2012 ABINIT group (MG)
!! This file is distributed under the terms of the
!! GNU General Public License, see ~abinit/COPYING
!! or http://www.gnu.org/copyleft/gpl.txt .
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

#if defined HAVE_CONFIG_H
#include "config.h"
#endif

#include "abi_common.h"


MODULE m_io_tools

 use m_profiling

 use defs_basis
 use m_fstrings

 implicit none

 private

! === List of available public routines and functions ===
 public :: get_unit         ! Get a free unit if no argument is specified or report the unit associated to a file name
 public :: open_file        ! Open a file after having performed some bacic tests
 public :: file_exist       ! Return .TRUE. if file exists.
 public :: delete_file      ! Delete a file if present.
 public :: is_open          ! .TRUE. if file is open
 public :: is_connected     ! .TRUE. if file is connected to a logical unit number
 public :: prompt           ! Simple prompt
 public :: read_line        ! Read line from unit ignoring blank lines and deleting comments beginning with !
 public :: flush_unit       ! Wrapper to the intrinsic flush routine, not implemented by every compiler
 public :: pick_aname       ! Returns the name of a non-existent file to be used for temporary storage.
 public :: is_netcdf_file   ! .TRUE. if we have a NETCDF file.
 public :: mvrecord         ! Moves forward or backward in a Fortran binary file by nn records.

 interface get_unit
  module procedure get_free_unit
  module procedure get_unit_from_fname
 end interface

 interface is_open
  module procedure is_open_unit
  module procedure is_open_fname
 end interface

 interface prompt
  module procedure prompt_int0D
  module procedure prompt_rdp0D
  module procedure prompt_string
  module procedure prompt_int1D
  module procedure prompt_int2D
  module procedure prompt_rdp1D
  module procedure prompt_rdp2D
 end interface

  integer,parameter :: STDIN=std_in
  integer,parameter :: STDOUT=std_out_default
  integer,parameter :: MIN_UNIT_NUMBER=10  ! Fortran does not define the range for logical unit numbers (they not be negative)
  integer,parameter :: MAX_UNIT_NUMBER=99  ! The following values should be safe
  integer,parameter :: IO_MAX_LEN=500
  character(len=1),parameter :: BLANK=' '

  ! === For Interactive sessions ===
  integer,parameter :: IO_EOT=-1           ! End of transmission i.e CTRL+D
  character(len=4),parameter :: PS1='>>> '
  character(len=4),parameter :: PS2='??? '

  ! === Built in IO exceptions, negative identifiers are used ===
  integer,parameter :: ERROR_UNKNOWN=-2          ! No units are available for Fortran I/O
  integer,parameter :: IO_NO_AVAILABLE_UNIT=-3  ! No units are available for Fortran I/O
  integer,parameter :: IO_FILE_EXISTS=-4         ! File already exists
  integer,parameter :: IO_FILE_DOES_NOT_EXIST=-5 ! File does not already exist
  integer,parameter :: IO_FILE_IS_OPEN=-6        ! File is already open
  integer,parameter :: IO_FILE_NOT_ASSOCIATED=-7 ! File is not associated with any unit
  !integer,parameter :: IO_END_OF_FILE=-8        ! End of file reached

CONTAINS  !===========================================================
!!***

!!****f* m_io_tools/get_unit
!! NAME
!!  get_unit
!!
!! FUNCTION
!!  Obtain a logical Fortran unit.
!!  A free unit is reported if no argument is specified.
!!  If the file name is supplied, the function reports the unit number
!!  associated to the file
!!
!! INPUTS
!!
!! OUTPUT
!!  The unit number (free unit or unit associated to the file)
!!  Raises:
!!   IO_NO_AVAILABLE_UNIT if no logical unit is free (!)
!!   IO_FILE_NOT_ASSOCIATED if the file is not linked to a logical unit
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

integer function get_free_unit()

!Local variables-------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'get_free_unit'
!End of the abilint section

 integer :: iunt
 logical :: isopen
! *********************************************************************

 do iunt=MIN_UNIT_NUMBER,MAX_UNIT_NUMBER
  inquire(unit=iunt,opened=isopen)
  if (.not.isopen) then
   get_free_unit=iunt ; RETURN
  end if
 end do
 get_free_unit=IO_NO_AVAILABLE_UNIT

end function get_free_unit
!!***

!!****f* m_io_tools/get_unit_from_fname
!! NAME
!! get_unit_from_fname
!!
!! FUNCTION
!!  Returns the unit number associated to an open file whose name is fname.
!!  If the file is not connected to an unit number, returns IO_FILE_NOT_ASSOCIATED
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
integer function get_unit_from_fname(fname)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'get_unit_from_fname'
!End of the abilint section

 character(len=*),intent(in) :: fname

!Local variables-------------------------------
 integer :: unit
! *********************************************************************

 inquire(file=fname,number=unit)

 get_unit_from_fname=unit
 if (unit==-1) get_unit_from_fname=IO_FILE_NOT_ASSOCIATED

end function get_unit_from_fname
!!***

!!****f* m_io_tools/open_file
!! NAME
!!  open_file
!!
!! FUNCTION
!! Low-level routine to open a file.
!! Opens file fname and returns the unit number associated to it.
!! Raises internal exceptions if an error occurred while accessing fname.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! CHILDREN
!!
!! PARENTS
!!
!! SOURCE
integer function open_file(fname,status,form,access,unit) result(unt)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'open_file'
!End of the abilint section

 integer,optional,intent(in) :: unit
 character(len=*),intent(in) :: fname,status,form,access

!!Local variables-------------------------------
 integer :: ios
 logical :: exists,is_open
! *********************************************************************

 inquire(file=fname,exist=exists,opened=is_open)
 if (is_open) then
  unt=IO_FILE_IS_OPEN ; RETURN
 end if

 if (exists.and.toupper(status)=='NEW') then
  unt=IO_FILE_EXISTS ; RETURN
 end if

 if (.not.exists.and.toupper(status)=='OLD') then
  unt=IO_FILE_DOES_NOT_EXIST ; RETURN
 end if

 if (PRESENT(unit)) then
  unt=unit
 else
  unt=get_unit() ; if (unt==IO_NO_AVAILABLE_UNIT) RETURN
 end if
 !
 ! === Now we can open the file ===
 open(unit=unt,file=fname,status=status,form=form,access=access,iostat=ios)
 if (ios/=0) unt=ERROR_UNKNOWN

end function open_file
!!***

!!****f* m_io_tools/file_exist
!! NAME
!!  file_exist
!!
!! FUNCTION
!!  Return .TRUE. if file existent (function version of inquire).
!!
!! INPUTS
!!  fname=The name of the file.
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
function file_exist(fname)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'file_exist'
!End of the abilint section

 logical :: file_exist
 character(len=*),intent(in) :: fname

! *********************************************************************

 inquire(file=fname,exist=file_exist)
 RETURN

end function file_exist
!!***

!!****f* m_io_tools/delete_file
!! NAME
!!  delete_file
!!
!! FUNCTION
!!  Delete a file if present.
!!
!! INPUTS
!!  fname=The name of the file.
!!
!! OUTPUT
!!  ierr=Non-zero value indicates that a problem occured.
!!   111 = To signal that the file does not exist.
!!   112 = File exist, is open but no associated unit is found!
!!   Other values are system-dependent as the value is returned by a open or close
!!   instruction.
!!
!! SIDE EFFECTS
!!  The specified file is deleted.
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine delete_file(fname,ierr)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'delete_file'
!End of the abilint section

 integer,intent(out) :: ierr
 character(len=*),intent(in) :: fname

!Local variables-------------------------------
 integer :: tmp_unt
 logical :: exists
! *********************************************************************

 ierr=0

 inquire(file=fname,exist=exists)

 if (.not.exists) then
  ierr=111
  write(std_out,*)" Asked to delete not existent file: ",TRIM(fname)
  RETURN
 end if

 if (is_open_fname(fname)) then
  tmp_unt = get_unit_from_fname(fname)
  if ( tmp_unt == IO_FILE_NOT_ASSOCIATED ) then
   write(std_out,*) "File is opened but no associated unit found!"
   ierr=112
   RETURN
  end if
  close(tmp_unt)
 else
  tmp_unt = get_unit()
 end if

 ! Now close the file.
 open(unit=tmp_unt,file=fname,status="OLD",iostat=ierr)
 if (ierr==0) close(unit=tmp_unt,status="DELETE",iostat=ierr)

end subroutine delete_file
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/is_connected
!! NAME
!!  is_connected
!!
!! FUNCTION
!!  Returns .TRUE. if unit is connected to fname.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
logical function is_connected(unit,fname)

!!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'is_connected'
!End of the abilint section

 integer,intent(in) :: unit
 character(len=*),intent(in) :: fname

!Local variables-------------------------------
 integer :: unt_found
 logical :: isopen
! *********************************************************************

 inquire(file=fname,number=unt_found,opened=isopen)
 is_connected=(isopen.and.(unt_found==unit))

end function is_connected
!!***

!!****f* m_io_tools/is_open
!! NAME
!!  is_open
!!
!! FUNCTION
!!  Returns .TRUE. if unit is associated to an open file.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

logical function is_open_unit(unit)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'is_open_unit'
!End of the abilint section

 integer,intent(in) :: unit
! *********************************************************************

 inquire(unit=unit,opened=is_open_unit)

end function is_open_unit
!!***

!!****f* m_io_tools/is_open_fname
!! NAME
!!  is_open_fname
!!
!! FUNCTION
!!  Returns .TRUE. if the file name fname is open.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

logical function is_open_fname(fname)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'is_open_fname'
!End of the abilint section

 character(len=*),intent(in) :: fname
! *********************************************************************

 inquire(file=fname,opened=is_open_fname)

end function is_open_fname
!!***

!!****f* m_io_tools/check_unit
!! NAME
!!  check_unit
!!
!! FUNCTION
!!  Test the result of an opening of a file and. If something went wrong, print an error
!!  message with useful information of the nature of the problem.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

subroutine check_unit(unit,fatal)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'check_unit'
!End of the abilint section

 integer,intent(in) :: unit
 logical,optional,intent(in) :: fatal

!Local variables-------------------------------
 integer :: ierr=-1
 logical :: is_fatal
! *********************************************************************

 is_fatal=.TRUE. ; if (PRESENT(fatal)) is_fatal=fatal

 select case (unit)
 case (ERROR_UNKNOWN)
  write(std_out,*)' Error unknown'
 case (IO_NO_AVAILABLE_UNIT)
  write(std_out,*)' Not able to find a free Fortran unit! '
 case (IO_FILE_EXISTS)
  write(std_out,*)' File already exists'
 case (IO_FILE_DOES_NOT_EXIST)
  write(std_out,*)'File does not exist'
 case (IO_FILE_IS_OPEN)
  write(std_out,*)'File is already open'
 case (IO_FILE_NOT_ASSOCIATED)
  write(std_out,*)'File is not associated with any unit'
 case default
  ierr=0
  continue
 end select

 if (ierr/=0.and.is_fatal) STOP

end subroutine check_unit
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_int0D
!! NAME
!!  prompt_int0D
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

subroutine prompt_int0D(msg,ivalue)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_int0D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 integer,intent(out) :: ivalue

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)ivalue
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_int0D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_rdp0d
!! NAME
!!  prompt_rdp0d
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

subroutine prompt_rdp0D(msg,rvalue)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_rdp0D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 real(dp),intent(out) :: rvalue

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)rvalue
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_rdp0D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_string
!! NAME
!!  prompt_string
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_string(msg,string)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_string'
!End of the abilint section

 character(len=*),intent(in) :: msg
 character(len=*),intent(out) :: string

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,'(a)',IOSTAT=ios)string
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_string
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_int1D
!! NAME
!!  prompt_int1D
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_int1D(msg,ivect)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_int1D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 integer,intent(out) :: ivect(:)

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)ivect(:)
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_int1D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_int2D
!! NAME
!!  prompt_int2d
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_int2D(msg,iarr)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_int2D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 integer,intent(out) :: iarr(:,:)

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)iarr(:,:)
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_int2D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_rdp1D
!! NAME
!!  prompt_rdp1D
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_rdp1D(msg,rvect)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_rdp1D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 real(dp),intent(out) :: rvect(:)
 character(len=4) :: PS
!Local variables-------------------------------
 integer :: ios
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)rvect(:)
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_rdp1D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_rdp2D
!! NAME
!!  prompt_rdp2D
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_rdp2D(msg,rarr)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_rdp2D'
!End of the abilint section

 character(len=*),intent(in) :: msg
 real(dp),intent(out) :: rarr(:,:)

!Local variables-------------------------------
 integer :: ios
 character(len=4) :: PS
! *********************************************************************

 ios=-1 ; PS=PS1
 do while (ios/=0)
  write(STDOUT,'(a)',ADVANCE='NO')PS//TRIM(msg)//BLANK
  read(STDIN,*,IOSTAT=ios)rarr(:,:)
  if (ios==IO_EOT) call prompt_exit()
  PS=PS2
 end do
 write(STDOUT,*)

end subroutine prompt_rdp2D
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/prompt_exit
!! NAME
!!  prompt_exit
!!
!! FUNCTION
!!  A primitive prompt. Writes msg on STDOUT and reads the value entered by the user.
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!      m_io_tools
!!
!! CHILDREN
!!
!! SOURCE
subroutine prompt_exit()

!Local variables-------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'prompt_exit'
!End of the abilint section

 integer,parameter :: NASK=5
 integer :: ios,iask
 character(len=IO_MAX_LEN) :: ans
! *********************************************************************

 write(STDOUT,*)
 ios=-1 ; iask=0
 do while (ios/=0.or.(ans/='y'.or.ans/='n'))
  iask=iask+1
  write(STDOUT,'(a)')' Do you really want to exit (y/n)? '
  read(STDIN,*,IOSTAT=ios)ans
  if (ans=='y'.or.iask>NASK) STOP
  if (ans=='n') RETURN
 end do

end subroutine prompt_exit
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/read_line
!! NAME
!!  read_line
!!
!! FUNCTION
!!  Reads line from unit=std_in_ or unit if specified, ignoring blank lines
!!  and deleting comments beginning with !
!!
!! INPUTS
!!
!! OUTPUT
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

subroutine read_line(line,ios,unit,comment)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'read_line'
!End of the abilint section

 character(len=*),intent(out):: line
 character(len=1),optional,intent(in) :: comment
 integer,optional,intent(in) :: unit
 integer,intent(out) :: ios

!Local variables-------------------------------
 integer :: ipos,unt
! *********************************************************************

 unt=STDIN ; if (PRESENT(unit)) unt=unit

 do
  read(unt,'(a)',iostat=ios) line  ! read input line
  if (ios/=0) RETURN
  line=ADJUSTL(line)
  if (PRESENT(comment)) then
    ipos=INDEX(line,comment)
    if (ipos==1) CYCLE
    if (ipos/=0) line=line(:ipos-1)
  end if
  if (LEN_TRIM(line)/=0) EXIT
 end do

end subroutine read_line
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/flush_unit
!! NAME
!! flush_unit
!!
!! FUNCTION
!! Wrapper for the standard flush_unit routine
!!
!! INPUTS
!!  [unit]=the unit number to be flushed (if not specified ALL open units are flushed)
!!
!! OUTPUT
!!
!! NOTES
!!  Available only if the compiler implements this intrinsic procedure.
!!
!! PARENTS
!!      calc_sigc_me,defs_scalapack,exc_build_block,exc_diago
!!      exc_iterative_diago,gstateimg,hdr_io,hdr_skip,initmpi_img,m_atprj
!!      m_bands_sym,m_errors,m_green,m_shirley,m_wfs,newvtr3,pawmkaewf
!!      prep_kpgio,spectral
!!
!! CHILDREN
!!
!! SOURCE

subroutine flush_unit(unit)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'flush_unit'
!End of the abilint section

 integer,optional,intent(in) :: unit

!Local variables-------------------------------
 integer :: unt
 logical :: isopen
!************************************************************************

 if (PRESENT(unit)) then
  unt=unit
  inquire(unit=unt,opened=isopen)
! FLUSH on unconnected unit is illegal: F95 std., 9.3.5.
#if defined HAVE_FC_FLUSH
  if (isopen) call flush(unt)
#elif defined HAVE_FC_FLUSH_
  if (isopen) call flush_(unt)
#endif
 else
#if defined HAVE_FC_FLUSH
  call flush()
#elif defined HAVE_FC_FLUSH_
  call flush_()
#endif
 end if

end subroutine flush_unit
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/pick_aname
!! NAME
!!  pick_aname
!!
!! FUNCTION
!!  Returns the name of a non-existent file to be used for temporary storage.
!!
!! INPUTS
!!  [prefix]=Prefix to be used for the temporary file. Cannot be larger than fnlen chars. Defaults to none.
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

function pick_aname(prefix) result(aname)

!Arguments ------------------------------------

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'pick_aname'
!End of the abilint section

 character(len=fnlen) :: aname
 character(len=*),optional,intent(in) :: prefix

!Local variables-------------------------------
 integer :: ii,spt,ept
 real(dp) :: xrand(fnlen)
!************************************************************************

 aname="__TMP_FILE__"; if (PRESENT(prefix)) aname = prefix

 spt=LEN(aname); ept=spt

 do while (file_exist(aname))
   call RANDOM_NUMBER(xrand(spt:ept))
   xrand = xrand*127
   do ii=spt,ept
    aname(ii:ii) = ACHAR(NINT(xrand(ii)))
   end do
   ept = MIN(ept+1,fnlen)
 end do

end function pick_aname
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/is_netcdf_file
!! NAME
!! is_netcdf_file
!!
!! FUNCTION
!!  Returns .TRUE. if fname is a NETCDF file.
!!
!! INPUTS
!!  fname(len=*)=The name of the file to be tested.
!!
!! NOTES
!!  The idea is extremely simple: a NETCDF file terminates with ".nc".
!!  Obviously this approach is not bulletproof but it will work
!!  provided that we continue to append the ".nc" string to any NETCDF
!!  file produced by abinit.
!!
!! PARENTS
!!
!! CHILDREN
!!
!! SOURCE

function is_netcdf_file(fname)

 use defs_basis

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'is_netcdf_file'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 character(len=*),intent(in) :: fname
 logical :: is_netcdf_file

!Local variables-------------------------------
!scalars
 integer :: ic,nch_trim

! *************************************************************************

 nch_trim=LEN_TRIM(fname)
 ic = INDEX (TRIM(fname), ".", back=.TRUE.)

 is_netcdf_file=.FALSE.
 if (ic >= 1 .and. ic <= nch_trim-1) then ! there is stuff after .
  is_netcdf_file = (fname(ic+1:nch_trim)=="nc")
 end if

end function is_netcdf_file
!!***

!----------------------------------------------------------------------

!!****f* m_io_tools/mvrecord
!! NAME
!! mvrecord
!!
!! FUNCTION
!! This subroutine moves forward or backward in a Fortran binary file by nn records.
!!
!! INPUTS
!! nrec=number of records
!! unitfile= file unit number
!!
!! OUTPUT
!! ierr=error code
!!
!! TODO
!! One should treat the possible errors of backspace
!!
!! PARENTS
!!      wffreadskiprec
!!
!! CHILDREN
!!
!! SOURCE

subroutine mvrecord(ierr,nrec,unitfile)

 use defs_basis

!This section has been created automatically by the script Abilint (TD).
!Do not modify the following lines by hand.
#undef ABI_FUNC
#define ABI_FUNC 'mvrecord'
!End of the abilint section

 implicit none

!Arguments ------------------------------------
!scalars
 integer,intent(in) :: nrec,unitfile
 integer,intent(out) :: ierr

!Local variables-------------------------------
!scalars
 integer :: irec

! *************************************************************************

 if ( nrec > 0) then ! Move forward nrec records
   do irec=1,nrec
     read(unitfile,iostat=ierr)
   end do
 else                ! Move backward nrec records
   do irec=1,-nrec
     backspace (unit=unitfile,iostat=ierr)
   end do
 end if

end subroutine mvrecord
!!***

!----------------------------------------------------------------------

END MODULE m_io_tools
!!***
