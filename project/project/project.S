.section .text.init
.globl rvtest_entry_point

rvtest_entry_point:

    # set up PMP so all of memory is accessible and we don't trap when entering supervisor mode   
    # Define region 0 to cover all addresses as RWX


    nop 
    # switch to supervisor mode	
    # Set mstatus.MPP to 01, set MPEC to a trampoline address where supervisor should begin, do mret
    
	# fill in instructions here:	
    li t0, 0xf
    csrw pmpcfg0, t0
    li t0, 0xffffffff
    csrw pmpaddr0, t0
    li t2, 0x800                  # t2 = 0000_0000_1000_0000_0000, MPP [12:11] = 01
    csrs mstatus, t2
    la t2, supervisorstart
    csrw mepc, t2               #save machine mode address
    mret                     	# enter supervisor mode at supervisorstart
    nop

supervisorstart:                            # fill in instructions here 
    la t0, pagetable        	# get address of root page table | Page table value = 0x08001_0000
    # li t3, 0x800            # Address is now byte aligned (Check which way to shift)
	# li t4, 0x900   		
    # add t3, t3, t0      # t3 = 0x08001_0800   L1 Entries
    # add t4, t4, t0      # t4 = 0x08001_0900   L1 Entries
    
    li t1, 0x8004000F
    sw t1, 0x800(t0)
    li t1, 0x9004000F
    sw t1, 0x900(t0)
    la t0, pagetable
    srli t0, t0, 12
    li t1, 0x80000000
    or t0, t0, t1
         
    




    csrw satp, t0         	# enable virtual memory
    
    
    # now we are execuiting on virtual page 0x80000, which is also physical page 0x80000
    # (this can be whatever you want as long as you use the correct address defined in the proj)	
    li t0, 0x90000300       
    li t1, 42
    sw t1, 0(t0)


    la t0, testcode         # address of  a routine to run
    lui t1, 0x10000         
    add t0, t0, t1          # address of testcode on virtual page 0x90000 
    jr t0                   # jump to the testcode on Virtual page 0x90000, 
                            #   which still points to same code on physical page 0x80000
    nop                     # shouldn't be executed

testcode:
    li t0, 42                # do something

write_tohost:
    la s1, tohost           # terminate with write tohost
    li t0, 1                # 1 for success, 3 for failure
    sw t0, 0(s1)            # send success code (yay)
    sw zero, 4(s1)          # not obvious why Sail isn't terminating unless this write is done

self_loop:
    j self_loop

.align 4
tohost:
    .word 0

.data


.align 16
# root (L1) Page table situated at 0x80010000
pagetable:
.space 2048
.4byte 0x20004401
.space 252
.4byte 0x20004401

.align 12
# L0 page table situated at 0x80011000
.4byte 0x200000CF

