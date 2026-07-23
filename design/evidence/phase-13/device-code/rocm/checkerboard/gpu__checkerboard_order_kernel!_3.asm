	.text
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1100"
	.amdhsa_code_object_version 5
	.p2align	2                               ; -- Begin function julia_ArgumentError_17125
	.type	julia_ArgumentError_17125,@function
julia_ArgumentError_17125:              ; @julia_ArgumentError_17125
.Lfunc_begin0:
	.file	1 "." "boot.jl"
	.loc	1 431 0                         ; boot.jl:431:0
	.cfi_sections .debug_frame
	.cfi_startproc
; %bb.0:                                ; %top
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
.Ltmp0:
	.loc	1 431 0 prologue_end            ; boot.jl:431:0
	s_setpc_b64 s[30:31]
.Ltmp1:
.Lfunc_end0:
	.size	julia_ArgumentError_17125, .Lfunc_end0-julia_ArgumentError_17125
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 8
; NumSgprs: 32
; NumVgprs: 0
; ScratchSize: 0
; MemoryBound: 0
	.text
	.protected	__ockl_devmem_request   ; -- Begin function __ockl_devmem_request
	.weak	__ockl_devmem_request
	.p2align	2
	.type	__ockl_devmem_request,@function
__ockl_devmem_request:                  ; @__ockl_devmem_request
.Lfunc_begin1:
	.cfi_startproc
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	s_mov_b32 s0, s33
	s_mov_b32 s33, s32
	s_or_saveexec_b32 s1, -1
	scratch_store_b32 off, v44, s33 offset:16 ; 4-byte Folded Spill
	s_mov_b32 exec_lo, s1
	v_writelane_b32 v44, s0, 11
	s_clause 0x3
	scratch_store_b32 off, v40, s33 offset:12
	scratch_store_b32 off, v41, s33 offset:8
	scratch_store_b32 off, v42, s33 offset:4
	scratch_store_b32 off, v43, s33
	v_mbcnt_lo_u32_b32 v4, -1, 0
	v_mov_b32_e32 v6, 0
	v_mov_b32_e32 v7, 0
	v_writelane_b32 v44, s30, 0
	s_add_i32 s32, s32, 32
	v_writelane_b32 v44, s31, 1
	v_writelane_b32 v44, s34, 2
	v_writelane_b32 v44, s35, 3
	v_writelane_b32 v44, s36, 4
	v_writelane_b32 v44, s37, 5
	s_load_b64 s[36:37], s[8:9], 0x50
	;;#ASMSTART
	;;#ASMEND
	v_readfirstlane_b32 s0, v4
	v_writelane_b32 v44, s38, 6
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_eq_u32_e64 s34, s0, v4
	v_writelane_b32 v44, s39, 7
	v_writelane_b32 v44, s40, 8
	v_writelane_b32 v44, s41, 9
	v_writelane_b32 v44, s42, 10
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB1_6
; %bb.1:
	v_mov_b32_e32 v5, 0
	s_mov_b32 s1, exec_lo
	s_waitcnt lgkmcnt(0)
	global_load_b64 v[8:9], v5, s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	s_clause 0x1
	global_load_b64 v[6:7], v5, s[36:37] offset:40
	global_load_b64 v[10:11], v5, s[36:37]
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v6, v6, v8
	v_and_b32_e32 v7, v7, v9
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v12, v6, 24
	v_mul_lo_u32 v7, v7, 24
	v_mul_lo_u32 v6, v6, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v7, v12, v7
	s_waitcnt vmcnt(0)
	v_add_co_u32 v6, vcc_lo, v10, v6
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v7, vcc_lo, v11, v7, vcc_lo
	global_load_b64 v[6:7], v[6:7], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[6:7], v5, v[6:9], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmpx_ne_u64_e64 v[6:7], v[8:9]
	s_cbranch_execz .LBB1_5
; %bb.2:                                ; %.preheader2
	s_mov_b32 s2, 0
	.p2align	6
.LBB1_3:                                ; =>This Inner Loop Header: Depth=1
	s_sleep 1
	s_clause 0x1
	global_load_b64 v[10:11], v5, s[36:37] offset:40
	global_load_b64 v[12:13], v5, s[36:37]
	v_dual_mov_b32 v9, v7 :: v_dual_mov_b32 v8, v6
	s_waitcnt vmcnt(1)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_and_b32_e32 v10, v10, v8
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[6:7], null, v10, 24, v[12:13]
	v_and_b32_e32 v12, v11, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mad_u64_u32 v[10:11], null, v12, 24, v[7:8]
	v_mov_b32_e32 v7, v10
	global_load_b64 v[6:7], v[6:7], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[6:7], v5, v[6:9], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmp_eq_u64_e32 vcc_lo, v[6:7], v[8:9]
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB1_3
; %bb.4:                                ; %Flow22
	s_or_b32 exec_lo, exec_lo, s2
.LBB1_5:                                ; %Flow24
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
.LBB1_6:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s0
	v_mov_b32_e32 v5, 0
	v_readfirstlane_b32 s38, v6
	v_readfirstlane_b32 s39, v7
	s_mov_b64 s[0:1], exec
	s_waitcnt lgkmcnt(0)
	s_clause 0x1
	global_load_b64 v[8:9], v5, s[36:37] offset:40
	global_load_b128 v[40:43], v5, s[36:37]
	s_waitcnt vmcnt(1)
	v_readfirstlane_b32 s2, v8
	v_readfirstlane_b32 s3, v9
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[38:39], s[2:3]
	s_mul_i32 s35, s3, 24
	s_mul_hi_u32 s40, s2, 24
	s_mul_i32 s41, s2, 24
	s_and_saveexec_b32 s16, s34
	s_cbranch_execz .LBB1_8
; %bb.7:
	s_add_i32 s17, s40, s35
	s_waitcnt vmcnt(0)
	v_add_co_u32 v10, vcc_lo, v40, s41
	v_add_co_ci_u32_e32 v11, vcc_lo, s17, v41, vcc_lo
	v_dual_mov_b32 v7, s1 :: v_dual_mov_b32 v6, s0
	v_dual_mov_b32 v8, 3 :: v_dual_mov_b32 v9, 1
	global_store_b128 v[10:11], v[6:9], off offset:8
.LBB1_8:
	s_or_b32 exec_lo, exec_lo, s16
	s_lshl_b64 s[2:3], s[2:3], 12
	v_lshlrev_b64 v[4:5], 6, v[4:5]
	s_waitcnt vmcnt(0)
	v_add_co_u32 v6, vcc_lo, v42, s2
	v_add_co_ci_u32_e32 v7, vcc_lo, s3, v43, vcc_lo
	s_mov_b32 s0, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_u32 v42, vcc_lo, v6, v4
	s_mov_b32 s3, s0
	s_mov_b32 s1, s0
	s_mov_b32 s2, s0
	v_add_co_ci_u32_e32 v43, vcc_lo, v7, v5, vcc_lo
	v_dual_mov_b32 v7, s3 :: v_dual_mov_b32 v6, s2
	v_dual_mov_b32 v5, s1 :: v_dual_mov_b32 v4, s0
	s_clause 0x3
	global_store_b128 v[42:43], v[0:3], off
	global_store_b128 v[42:43], v[4:7], off offset:16
	global_store_b128 v[42:43], v[4:7], off offset:32
	global_store_b128 v[42:43], v[4:7], off offset:48
	s_and_saveexec_b32 s42, s34
	s_cbranch_execz .LBB1_13
; %bb.9:
	v_mov_b32_e32 v6, 0
	s_mov_b32 s0, exec_lo
	s_clause 0x1
	global_load_b64 v[9:10], v6, s[36:37] offset:32 glc
	global_load_b64 v[0:1], v6, s[36:37] offset:40
	v_dual_mov_b32 v7, s38 :: v_dual_mov_b32 v8, s39
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v1, s39, v1
	v_and_b32_e32 v0, s38, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v2, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v2, v1
	v_add_co_u32 v4, vcc_lo, v40, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v5, vcc_lo, v41, v1, vcc_lo
	global_store_b64 v[4:5], v[9:10], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v6, v[7:10], s[36:37] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmpx_ne_u64_e64 v[2:3], v[9:10]
	s_cbranch_execz .LBB1_12
; %bb.10:                               ; %.preheader1
	s_mov_b32 s1, 0
.LBB1_11:                               ; =>This Inner Loop Header: Depth=1
	v_dual_mov_b32 v0, s38 :: v_dual_mov_b32 v1, s39
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[0:1], v6, v[0:3], s[36:37] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB1_11
.LBB1_12:                               ; %Flow20
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v3, 0
	v_mov_b32_e32 v2, 1
	v_mov_b32_e32 v4, 3
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, __ockl_hsa_signal_add@rel32@lo+4
	s_addc_u32 s1, s1, __ockl_hsa_signal_add@rel32@hi+12
	global_load_b64 v[0:1], v0, s[36:37] offset:16
	s_swappc_b64 s[30:31], s[0:1]
.LBB1_13:                               ; %Flow21
	s_or_b32 exec_lo, exec_lo, s42
	s_add_i32 s40, s40, s35
	v_add_co_u32 v0, vcc_lo, v40, s41
	v_add_co_ci_u32_e32 v1, vcc_lo, s40, v41, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v0, 20
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v1, vcc_lo
	s_branch .LBB1_17
	.p2align	6
.LBB1_14:                               ;   in Loop: Header=BB1_17 Depth=1
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_readfirstlane_b32 s0, v2
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB1_16
; %bb.15:                               ;   in Loop: Header=BB1_17 Depth=1
	s_sleep 1
	s_cbranch_execnz .LBB1_17
	s_branch .LBB1_19
	.p2align	6
.LBB1_16:
	s_branch .LBB1_19
.LBB1_17:                               ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v2, 1
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB1_14
; %bb.18:                               ;   in Loop: Header=BB1_17 Depth=1
	global_load_b32 v2, v[0:1], off glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_and_b32_e32 v2, 1, v2
	s_branch .LBB1_14
.LBB1_19:
	global_load_b64 v[0:1], v[42:43], off
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB1_23
; %bb.20:
	v_mov_b32_e32 v8, 0
	s_clause 0x2
	global_load_b64 v[4:5], v8, s[36:37] offset:40
	global_load_b64 v[9:10], v8, s[36:37] offset:24 glc
	global_load_b64 v[6:7], v8, s[36:37]
	s_waitcnt vmcnt(2)
	v_add_co_u32 v11, vcc_lo, v4, 1
	v_add_co_ci_u32_e32 v12, vcc_lo, 0, v5, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v2, vcc_lo, v11, s38
	v_add_co_ci_u32_e32 v3, vcc_lo, s39, v12, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]
	v_dual_cndmask_b32 v3, v3, v12 :: v_dual_cndmask_b32 v2, v2, v11
	v_and_b32_e32 v5, v3, v5
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_and_b32_e32 v4, v2, v4
	v_mul_lo_u32 v5, v5, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v11, v4, 24
	v_mul_lo_u32 v4, v4, 24
	v_add_nc_u32_e32 v5, v11, v5
	s_waitcnt vmcnt(0)
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_add_co_u32 v6, vcc_lo, v6, v4
	v_mov_b32_e32 v4, v9
	v_add_co_ci_u32_e32 v7, vcc_lo, v7, v5, vcc_lo
	v_mov_b32_e32 v5, v10
	global_store_b64 v[6:7], v[9:10], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[4:5], v8, v[2:5], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, v[4:5], v[9:10]
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB1_23
; %bb.21:                               ; %.preheader
	s_mov_b32 s1, 0
.LBB1_22:                               ; =>This Inner Loop Header: Depth=1
	s_sleep 1
	global_store_b64 v[6:7], v[4:5], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[9:10], v8, v[2:5], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[4:5]
	v_dual_mov_b32 v4, v9 :: v_dual_mov_b32 v5, v10
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB1_22
.LBB1_23:                               ; %__ockl_hostcall_internal.exit
	s_or_b32 exec_lo, exec_lo, s0
	s_clause 0x3
	scratch_load_b32 v43, off, s33
	scratch_load_b32 v42, off, s33 offset:4
	scratch_load_b32 v41, off, s33 offset:8
	scratch_load_b32 v40, off, s33 offset:12
	v_readlane_b32 s42, v44, 10
	v_readlane_b32 s41, v44, 9
	v_readlane_b32 s40, v44, 8
	v_readlane_b32 s39, v44, 7
	v_readlane_b32 s38, v44, 6
	v_readlane_b32 s37, v44, 5
	v_readlane_b32 s36, v44, 4
	v_readlane_b32 s35, v44, 3
	v_readlane_b32 s34, v44, 2
	v_readlane_b32 s31, v44, 1
	v_readlane_b32 s30, v44, 0
	v_readlane_b32 s0, v44, 11
	s_or_saveexec_b32 s1, -1
	scratch_load_b32 v44, off, s33 offset:16 ; 4-byte Folded Reload
	s_mov_b32 exec_lo, s1
	s_addk_i32 s32, 0xffe0
	s_mov_b32 s33, s0
	s_waitcnt vmcnt(0)
	s_setpc_b64 s[30:31]
.Lfunc_end1:
	.size	__ockl_devmem_request, .Lfunc_end1-__ockl_devmem_request
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 1612
; NumSgprs: 45
; NumVgprs: 45
; ScratchSize: 32
; MemoryBound: 0
	.text
	.protected	__ockl_hsa_signal_add   ; -- Begin function __ockl_hsa_signal_add
	.weak	__ockl_hsa_signal_add
	.p2align	2
	.type	__ockl_hsa_signal_add,@function
__ockl_hsa_signal_add:                  ; @__ockl_hsa_signal_add
.Lfunc_begin2:
	.cfi_startproc
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	s_mov_b32 s0, 0
	s_mov_b32 s1, 0
	s_mov_b32 s2, exec_lo
	v_cmpx_lt_i32_e32 3, v4
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execz .LBB0_8
; %bb.1:                                ; %NodeBlock12
	s_mov_b32 s3, 0
	s_mov_b32 s1, exec_lo
	v_cmpx_lt_i32_e32 4, v4
	s_xor_b32 s1, exec_lo, s1
	s_cbranch_execz .LBB0_5
; %bb.2:                                ; %LeafBlock10
	s_mov_b32 s3, -1
	s_mov_b32 s4, exec_lo
	v_cmpx_eq_u32_e32 5, v4
	s_cbranch_execz .LBB0_4
; %bb.3:
	s_waitcnt_vscnt null, 0x0
	global_atomic_add_u64 v[0:1], v[2:3], off offset:8
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
	s_xor_b32 s3, exec_lo, -1
.LBB0_4:                                ; %Flow17
	s_or_b32 exec_lo, exec_lo, s4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s3, s3, exec_lo
.LBB0_5:                                ; %Flow16
	s_and_not1_saveexec_b32 s1, s1
	s_cbranch_execz .LBB0_7
; %bb.6:
	s_waitcnt_vscnt null, 0x0
	global_atomic_add_u64 v[0:1], v[2:3], off offset:8
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.LBB0_7:                                ; %Flow18
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s1, s3, exec_lo
                                        ; implicit-def: $vgpr4
.LBB0_8:                                ; %Flow
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB0_14
; %bb.9:                                ; %NodeBlock
	s_mov_b32 s0, exec_lo
	v_cmpx_lt_i32_e32 2, v4
	s_xor_b32 s0, exec_lo, s0
	s_cbranch_execz .LBB0_11
; %bb.10:
	s_waitcnt_vscnt null, 0x0
	global_atomic_add_u64 v[0:1], v[2:3], off offset:8
                                        ; implicit-def: $vgpr4
.LBB0_11:                               ; %Flow20
	s_or_saveexec_b32 s3, s0
	s_mov_b32 s0, 0
	s_mov_b32 s4, s1
	s_xor_b32 exec_lo, exec_lo, s3
; %bb.12:                               ; %LeafBlock
	v_cmp_gt_i32_e32 vcc_lo, 1, v4
	s_and_not1_b32 s4, s1, exec_lo
	s_mov_b32 s0, exec_lo
	s_and_b32 s5, vcc_lo, exec_lo
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 s4, s4, s5
; %bb.13:                               ; %Flow21
	s_or_b32 exec_lo, exec_lo, s3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 s1, s1, exec_lo
	s_and_b32 s3, s4, exec_lo
	s_and_b32 s0, s0, exec_lo
	s_or_b32 s1, s1, s3
.LBB0_14:                               ; %Flow19
	s_or_b32 exec_lo, exec_lo, s2
	s_and_saveexec_b32 s2, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_xor_b32 s1, exec_lo, s2
	s_cbranch_execz .LBB0_16
; %bb.15:
	global_atomic_add_u64 v[0:1], v[2:3], off offset:8
	s_and_not1_b32 s0, s0, exec_lo
.LBB0_16:                               ; %Flow22
	s_or_b32 exec_lo, exec_lo, s1
	s_and_saveexec_b32 s1, s0
	s_cbranch_execz .LBB0_18
; %bb.17:
	global_atomic_add_u64 v[0:1], v[2:3], off offset:8
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.LBB0_18:
	s_or_b32 exec_lo, exec_lo, s1
	global_load_b64 v[2:3], v[0:1], off offset:16
	s_mov_b32 s0, exec_lo
	s_waitcnt vmcnt(0)
	v_cmpx_ne_u64_e32 0, v[2:3]
	s_cbranch_execz .LBB0_20
; %bb.19:
	global_load_b32 v0, v[0:1], off offset:24
	v_mov_b32_e32 v1, 0
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s1, v0
	s_waitcnt_vscnt null, 0x0
	global_store_b64 v[2:3], v[0:1], off
	s_and_b32 m0, s1, 0xff
	s_sendmsg sendmsg(MSG_INTERRUPT)
.LBB0_20:                               ; %UnifiedReturnBlock
	s_or_b32 exec_lo, exec_lo, s0
	s_waitcnt lgkmcnt(0)
	s_setpc_b64 s[30:31]
.Lfunc_end2:
	.size	__ockl_hsa_signal_add, .Lfunc_end2-__ockl_hsa_signal_add
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 420
; NumSgprs: 34
; NumVgprs: 5
; ScratchSize: 0
; MemoryBound: 0
	.text
	.protected	__ockl_dm_init_v1       ; -- Begin function __ockl_dm_init_v1
	.weak	__ockl_dm_init_v1
	.p2align	2
	.type	__ockl_dm_init_v1,@function
__ockl_dm_init_v1:                      ; @__ockl_dm_init_v1
.Lfunc_begin3:
	.cfi_startproc
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	v_and_b32_e32 v6, 0x3ff, v31
	s_mov_b32 s0, 0
	s_mov_b32 s4, exec_lo
	v_cmpx_ne_u32_e32 0, v4
	s_cbranch_execz .LBB2_2
; %bb.1:
	s_mov_b32 s1, s0
	s_mov_b32 s2, s0
	s_mov_b32 s3, s0
	v_lshlrev_b32_e32 v4, 4, v6
	v_dual_mov_b32 v10, s3 :: v_dual_mov_b32 v7, s0
	v_dual_mov_b32 v9, s2 :: v_dual_mov_b32 v8, s1
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_co_u32 v11, vcc_lo, v4, v0
	v_add_co_ci_u32_e32 v12, vcc_lo, 0, v1, vcc_lo
	v_add_co_u32 v13, vcc_lo, v11, 0x2000
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	s_clause 0x1
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	v_add_co_u32 v13, vcc_lo, v11, 0x4000
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v15, vcc_lo, v11, 0x6000
	v_add_co_ci_u32_e32 v16, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v17, vcc_lo, v11, 0x8000
	v_add_co_ci_u32_e32 v18, vcc_lo, 0, v12, vcc_lo
	s_clause 0x5
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	global_store_b128 v[15:16], v[7:10], off offset:-4096
	global_store_b128 v[15:16], v[7:10], off
	global_store_b128 v[17:18], v[7:10], off offset:-4096
	global_store_b128 v[17:18], v[7:10], off
	v_add_co_u32 v13, vcc_lo, v11, 0xa000
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v15, vcc_lo, v11, 0xc000
	v_add_co_ci_u32_e32 v16, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v17, vcc_lo, v11, 0xe000
	v_add_co_ci_u32_e32 v18, vcc_lo, 0, v12, vcc_lo
	s_clause 0x5
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	global_store_b128 v[15:16], v[7:10], off offset:-4096
	global_store_b128 v[15:16], v[7:10], off
	global_store_b128 v[17:18], v[7:10], off offset:-4096
	global_store_b128 v[17:18], v[7:10], off
	v_add_co_u32 v13, vcc_lo, v11, 0x10000
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v15, vcc_lo, v11, 0x12000
	v_add_co_ci_u32_e32 v16, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v17, vcc_lo, v11, 0x14000
	v_add_co_ci_u32_e32 v18, vcc_lo, 0, v12, vcc_lo
	s_clause 0x5
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	global_store_b128 v[15:16], v[7:10], off offset:-4096
	global_store_b128 v[15:16], v[7:10], off
	global_store_b128 v[17:18], v[7:10], off offset:-4096
	global_store_b128 v[17:18], v[7:10], off
	v_add_co_u32 v13, vcc_lo, v11, 0x16000
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v15, vcc_lo, v11, 0x18000
	v_add_co_ci_u32_e32 v16, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v17, vcc_lo, v11, 0x1a000
	v_add_co_ci_u32_e32 v18, vcc_lo, 0, v12, vcc_lo
	s_clause 0x5
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	global_store_b128 v[15:16], v[7:10], off offset:-4096
	global_store_b128 v[15:16], v[7:10], off
	global_store_b128 v[17:18], v[7:10], off offset:-4096
	global_store_b128 v[17:18], v[7:10], off
	v_add_co_u32 v13, vcc_lo, v11, 0x1c000
	v_add_co_ci_u32_e32 v14, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v15, vcc_lo, v11, 0x1e000
	v_add_co_ci_u32_e32 v16, vcc_lo, 0, v12, vcc_lo
	v_add_co_u32 v17, vcc_lo, 0x1f000, v11
	v_add_co_ci_u32_e32 v18, vcc_lo, 0, v12, vcc_lo
	s_clause 0x5
	global_store_b128 v[13:14], v[7:10], off offset:-4096
	global_store_b128 v[13:14], v[7:10], off
	global_store_b128 v[15:16], v[7:10], off offset:-4096
	global_store_b128 v[15:16], v[7:10], off
	global_store_b128 v[11:12], v[7:10], off
	global_store_b128 v[17:18], v[7:10], off
.LBB2_2:
	s_or_b32 exec_lo, exec_lo, s4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mov_b32 s0, exec_lo
	v_cmpx_eq_u32_e32 0, v6
; %bb.3:
	v_mov_b32_e32 v6, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_3)
	v_lshlrev_b64 v[4:5], 21, v[5:6]
	v_add_co_u32 v6, vcc_lo, 0x1a000, v0
	v_add_co_ci_u32_e32 v7, vcc_lo, 0, v1, vcc_lo
	v_add_co_u32 v0, vcc_lo, v4, v2
	s_delay_alu instid0(VALU_DEP_4)
	v_add_co_ci_u32_e32 v1, vcc_lo, v5, v3, vcc_lo
	s_clause 0x1
	global_store_b64 v[6:7], v[2:3], off offset:2048
	global_store_b128 v[6:7], v[0:3], off offset:2056
; %bb.4:
	s_or_b32 exec_lo, exec_lo, s0
	s_setpc_b64 s[30:31]
.Lfunc_end3:
	.size	__ockl_dm_init_v1, .Lfunc_end3-__ockl_dm_init_v1
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 708
; NumSgprs: 34
; NumVgprs: 32
; ScratchSize: 0
; MemoryBound: 1
	.section	.text.unlikely.,"ax",@progbits
	.protected	__ockl_dm_trim          ; -- Begin function __ockl_dm_trim
	.weak	__ockl_dm_trim
	.p2align	2
	.type	__ockl_dm_trim,@function
__ockl_dm_trim:                         ; @__ockl_dm_trim
.Lfunc_begin4:
	.cfi_startproc
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	s_mov_b32 s0, s33
	s_mov_b32 s33, s32
	s_or_saveexec_b32 s1, -1
	s_clause 0x1
	scratch_store_b32 off, v94, s33 offset:120
	scratch_store_b32 off, v95, s33 offset:124
	s_mov_b32 exec_lo, s1
	v_writelane_b32 v94, s30, 0
	s_clause 0x1d
	scratch_store_b32 off, v40, s33 offset:116
	scratch_store_b32 off, v41, s33 offset:112
	scratch_store_b32 off, v42, s33 offset:108
	scratch_store_b32 off, v43, s33 offset:104
	scratch_store_b32 off, v44, s33 offset:100
	scratch_store_b32 off, v45, s33 offset:96
	scratch_store_b32 off, v46, s33 offset:92
	scratch_store_b32 off, v47, s33 offset:88
	scratch_store_b32 off, v56, s33 offset:84
	scratch_store_b32 off, v57, s33 offset:80
	scratch_store_b32 off, v58, s33 offset:76
	scratch_store_b32 off, v59, s33 offset:72
	scratch_store_b32 off, v60, s33 offset:68
	scratch_store_b32 off, v61, s33 offset:64
	scratch_store_b32 off, v62, s33 offset:60
	scratch_store_b32 off, v63, s33 offset:56
	scratch_store_b32 off, v72, s33 offset:52
	scratch_store_b32 off, v73, s33 offset:48
	scratch_store_b32 off, v74, s33 offset:44
	scratch_store_b32 off, v75, s33 offset:40
	scratch_store_b32 off, v76, s33 offset:36
	scratch_store_b32 off, v77, s33 offset:32
	scratch_store_b32 off, v78, s33 offset:28
	scratch_store_b32 off, v79, s33 offset:24
	scratch_store_b32 off, v88, s33 offset:20
	scratch_store_b32 off, v89, s33 offset:16
	scratch_store_b32 off, v90, s33 offset:12
	scratch_store_b32 off, v91, s33 offset:8
	scratch_store_b32 off, v92, s33 offset:4
	scratch_store_b32 off, v93, s33
	v_cmp_ne_u64_e32 vcc_lo, 0, v[0:1]
	v_mbcnt_lo_u32_b32 v47, -1, 0
	v_writelane_b32 v95, s0, 12
	v_writelane_b32 v94, s31, 1
	v_dual_mov_b32 v59, 1 :: v_dual_mov_b32 v46, 0
	v_cndmask_b32_e32 v78, -1, v0, vcc_lo
	v_lshlrev_b32_e32 v0, 2, v47
	v_writelane_b32 v94, s34, 2
	v_mov_b32_e32 v2, 0x1a000
	v_writelane_b32 v95, s64, 0
	v_dual_mov_b32 v40, v31 :: v_dual_add_nc_u32 v79, 0x100, v78
	v_writelane_b32 v94, s35, 3
	v_add_nc_u32_e32 v89, v78, v0
	v_writelane_b32 v95, s65, 1
	v_add_nc_u32_e32 v88, -4, v78
	v_add_nc_u32_e32 v90, v79, v0
	v_writelane_b32 v94, s36, 4
	v_not_b32_e32 v91, v47
	v_writelane_b32 v95, s66, 2
	v_mov_b32_e32 v58, 3
	s_mov_b64 s[34:35], s[8:9]
	v_writelane_b32 v94, s37, 5
	s_mov_b64 s[36:37], s[6:7]
	v_writelane_b32 v95, s67, 3
	s_addk_i32 s32, 0x90
	v_writelane_b32 v94, s38, 6
	v_writelane_b32 v95, s68, 4
	v_writelane_b32 v94, s39, 7
	s_mov_b64 s[38:39], s[10:11]
	v_writelane_b32 v95, s69, 5
	v_writelane_b32 v94, s40, 8
	v_writelane_b32 v95, s70, 6
	v_writelane_b32 v94, s41, 9
	s_mov_b64 s[40:41], s[4:5]
	v_writelane_b32 v95, s71, 7
	v_writelane_b32 v94, s42, 10
	s_mov_b32 s42, s15
	v_writelane_b32 v95, s72, 8
	v_writelane_b32 v94, s43, 11
	s_mov_b32 s43, s14
	v_writelane_b32 v95, s73, 9
	v_writelane_b32 v94, s44, 12
	s_mov_b32 s44, s13
	v_writelane_b32 v95, s74, 10
	v_writelane_b32 v94, s45, 13
	s_mov_b32 s45, s12
	v_writelane_b32 v95, s75, 11
	v_writelane_b32 v94, s46, 14
	v_cmp_eq_u32_e64 s46, 0, v47
	v_writelane_b32 v94, s47, 15
	v_writelane_b32 v94, s48, 16
	s_mov_b32 s48, 0
	v_writelane_b32 v94, s49, 17
	v_writelane_b32 v94, s50, 18
	v_writelane_b32 v94, s51, 19
	v_writelane_b32 v94, s52, 20
	v_writelane_b32 v94, s53, 21
	s_load_b64 s[52:53], s[8:9], 0x60
	v_writelane_b32 v94, s54, 22
	v_writelane_b32 v94, s55, 23
	s_getpc_b64 s[54:55]
	s_add_u32 s54, s54, __ockl_hsa_signal_add@rel32@lo+4
	s_addc_u32 s55, s55, __ockl_hsa_signal_add@rel32@hi+12
	v_writelane_b32 v94, s56, 24
	s_mov_b32 s56, 0
	v_writelane_b32 v94, s57, 25
	s_waitcnt lgkmcnt(0)
	global_load_b128 v[41:44], v2, s[52:53] offset:2056
	v_writelane_b32 v94, s58, 26
	v_writelane_b32 v94, s59, 27
	v_writelane_b32 v94, s60, 28
	v_writelane_b32 v94, s61, 29
	v_writelane_b32 v94, s62, 30
	v_writelane_b32 v94, s63, 31
.LBB3_1:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB3_5 Depth 2
                                        ;       Child Loop BB3_6 Depth 3
                                        ;         Child Loop BB3_15 Depth 4
                                        ;         Child Loop BB3_23 Depth 4
                                        ;         Child Loop BB3_26 Depth 4
                                        ;         Child Loop BB3_35 Depth 4
                                        ;       Child Loop BB3_41 Depth 3
                                        ;         Child Loop BB3_51 Depth 4
                                        ;         Child Loop BB3_59 Depth 4
                                        ;         Child Loop BB3_62 Depth 4
                                        ;         Child Loop BB3_71 Depth 4
                                        ;     Child Loop BB3_101 Depth 2
	v_mov_b32_e32 v0, v46
	s_and_saveexec_b32 s0, s46
	s_cbranch_execz .LBB3_3
; %bb.2:                                ;   in Loop: Header=BB3_1 Depth=1
	s_mov_b32 s57, s48
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_lshl_b64 s[2:3], s[56:57], 7
	s_add_u32 s2, s52, s2
	s_addc_u32 s3, s53, s3
	global_load_b32 v0, v46, s[2:3] offset:2048 glc
.LBB3_3:                                ;   in Loop: Header=BB3_1 Depth=1
	s_or_b32 exec_lo, exec_lo, s0
	s_waitcnt vmcnt(0)
	v_readfirstlane_b32 s62, v0
	s_delay_alu instid0(VALU_DEP_1)
	s_cmp_eq_u32 s62, 0
	s_cbranch_scc1 .LBB3_111
; %bb.4:                                ;   in Loop: Header=BB3_1 Depth=1
	v_mov_b32_e32 v62, 0
	v_mov_b32_e32 v92, 0
	s_add_i32 s0, s62, -1
	s_mov_b32 s57, s48
	s_and_b32 s65, s0, 0xffffffe0
	s_mov_b32 s66, 0
	s_mul_hi_u32 s63, s56, 0x1800
	s_mul_i32 s64, s56, 0x1800
	s_mov_b32 s68, 0
	s_mov_b32 s67, 0
.LBB3_5:                                ;   Parent Loop BB3_1 Depth=1
                                        ; =>  This Loop Header: Depth=2
                                        ;       Child Loop BB3_6 Depth 3
                                        ;         Child Loop BB3_15 Depth 4
                                        ;         Child Loop BB3_23 Depth 4
                                        ;         Child Loop BB3_26 Depth 4
                                        ;         Child Loop BB3_35 Depth 4
                                        ;       Child Loop BB3_41 Depth 3
                                        ;         Child Loop BB3_51 Depth 4
                                        ;         Child Loop BB3_59 Depth 4
                                        ;         Child Loop BB3_62 Depth 4
                                        ;         Child Loop BB3_71 Depth 4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_cmp_lt_u32 s67, s62
	s_cselect_b32 s69, -1, 0
	s_cmp_ge_u32 s67, s62
	s_cselect_b32 s0, -1, 0
	s_cmp_gt_u32 s66, 31
	s_cselect_b32 s1, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s0, s1, s0
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_39
.LBB3_6:                                ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB3_15 Depth 4
                                        ;         Child Loop BB3_23 Depth 4
                                        ;         Child Loop BB3_26 Depth 4
                                        ;         Child Loop BB3_35 Depth 4
	v_add_nc_u32_e32 v93, s67, v47
	s_mov_b32 s0, 0
	s_mov_b32 s69, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e64 s62, v93
	s_cbranch_execz .LBB3_38
; %bb.7:                                ;   in Loop: Header=BB3_6 Depth=3
	s_mov_b32 s0, exec_lo
                                        ; implicit-def: $vgpr76_vgpr77
	v_cmpx_gt_u32_e32 0x100, v93
	s_xor_b32 s0, exec_lo, s0
; %bb.8:                                ;   in Loop: Header=BB3_6 Depth=3
	s_add_u32 s1, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s1, 0x2800
	s_addc_u32 s3, s3, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mad_u64_u32 v[76:77], null, v93, 24, s[2:3]
; %bb.9:                                ; %Flow91
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB3_11
; %bb.10:                               ;   in Loop: Header=BB3_6 Depth=3
	v_add_nc_u32_e32 v0, 0xffffff00, v93
	s_add_u32 s1, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s1, 0x2800
	s_addc_u32 s3, s3, 0
	v_lshrrev_b32_e32 v2, 8, v0
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u64_u32 v[0:1], null, v2, 24, s[2:3]
	v_and_b32_e32 v2, 0xff, v93
	global_load_b64 v[0:1], v[0:1], off glc
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[76:77], null, v2, 24, v[0:1]
.LBB3_11:                               ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	s_clause 0x1
	global_load_b32 v0, v[76:77], off offset:16 glc
	global_load_b64 v[60:61], v[76:77], off offset:8 glc
	s_waitcnt vmcnt(1)
	v_cmp_eq_u32_e64 s2, 0, v0
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, 0, v[60:61]
	v_cmp_lt_u64_e64 s0, v[60:61], v[43:44]
	v_cmp_ge_u64_e64 s1, v[60:61], v[41:42]
	s_and_b32 s2, s2, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s0, s0, s1
	s_and_b32 s1, s2, s0
	s_mov_b32 s0, 0
	s_and_saveexec_b32 s70, s1
	s_cbranch_execz .LBB3_37
; %bb.12:                               ;   in Loop: Header=BB3_6 Depth=3
	s_load_b64 s[58:59], s[34:35], 0x50
	v_dual_mov_b32 v45, v47 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_readfirstlane_b32 s0, v45
	v_mov_b32_e32 v1, 0
	v_cmp_eq_u32_e64 s47, s0, v45
	s_delay_alu instid0(VALU_DEP_1)
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_18
; %bb.13:                               ;   in Loop: Header=BB3_6 Depth=3
	s_waitcnt lgkmcnt(0)
	global_load_b64 v[2:3], v46, s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	s_clause 0x1
	global_load_b64 v[0:1], v46, s[58:59] offset:40
	global_load_b64 v[4:5], v46, s[58:59]
	s_mov_b32 s1, exec_lo
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v1, v1, v3
	v_and_b32_e32 v0, v0, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v6, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v6, v1
	s_waitcnt vmcnt(0)
	v_add_co_u32 v0, vcc_lo, v4, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v1, vcc_lo, v5, v1, vcc_lo
	global_load_b64 v[0:1], v[0:1], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmpx_ne_u64_e64 v[0:1], v[2:3]
	s_cbranch_execz .LBB3_17
; %bb.14:                               ; %.preheader8
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_mov_b32 s2, 0
.LBB3_15:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_6 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	s_sleep 1
	s_clause 0x1
	global_load_b64 v[4:5], v46, s[58:59] offset:40
	global_load_b64 v[6:7], v46, s[58:59]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_waitcnt vmcnt(1)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_and_b32_e32 v4, v4, v2
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[0:1], null, v4, 24, v[6:7]
	v_and_b32_e32 v6, v5, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mad_u64_u32 v[4:5], null, v6, 24, v[1:2]
	v_mov_b32_e32 v1, v4
	global_load_b64 v[0:1], v[0:1], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB3_15
; %bb.16:                               ; %Flow86
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s2
.LBB3_17:                               ; %Flow88
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
.LBB3_18:                               ;   in Loop: Header=BB3_6 Depth=3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s0
	s_waitcnt lgkmcnt(0)
	s_clause 0x1
	global_load_b64 v[2:3], v46, s[58:59] offset:40
	global_load_b128 v[72:75], v46, s[58:59]
	v_readfirstlane_b32 s60, v0
	v_readfirstlane_b32 s61, v1
	s_mov_b64 s[0:1], exec
	s_waitcnt vmcnt(1)
	v_readfirstlane_b32 s2, v2
	v_readfirstlane_b32 s3, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[60:61], s[2:3]
	s_mul_i32 s71, s3, 24
	s_mul_hi_u32 s72, s2, 24
	s_mul_i32 s73, s2, 24
	s_and_saveexec_b32 s4, s47
	s_cbranch_execz .LBB3_20
; %bb.19:                               ;   in Loop: Header=BB3_6 Depth=3
	s_add_i32 s5, s72, s71
	s_waitcnt vmcnt(0)
	v_add_co_u32 v0, vcc_lo, v72, s73
	v_add_co_ci_u32_e32 v1, vcc_lo, s5, v73, vcc_lo
	v_dual_mov_b32 v57, s1 :: v_dual_mov_b32 v56, s0
	global_store_b128 v[0:1], v[56:59], off offset:8
.LBB3_20:                               ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s4
	s_lshl_b64 s[0:1], s[2:3], 12
	v_lshlrev_b64 v[0:1], 6, v[45:46]
	s_waitcnt vmcnt(0)
	v_add_co_u32 v2, vcc_lo, v74, s0
	v_add_co_ci_u32_e32 v3, vcc_lo, s1, v75, vcc_lo
	s_mov_b32 s49, s48
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_u32 v4, vcc_lo, v2, v0
	s_mov_b32 s50, s48
	s_mov_b32 s51, s48
	v_add_co_ci_u32_e32 v5, vcc_lo, v3, v1, vcc_lo
	v_dual_mov_b32 v63, v62 :: v_dual_mov_b32 v0, s48
	v_dual_mov_b32 v1, s49 :: v_dual_mov_b32 v2, s50
	v_mov_b32_e32 v3, s51
	s_clause 0x3
	global_store_b128 v[4:5], v[60:63], off
	global_store_b128 v[4:5], v[0:3], off offset:16
	global_store_b128 v[4:5], v[0:3], off offset:32
	global_store_b128 v[4:5], v[0:3], off offset:48
	s_and_saveexec_b32 s49, s47
	s_cbranch_execz .LBB3_25
; %bb.21:                               ;   in Loop: Header=BB3_6 Depth=3
	s_clause 0x1
	global_load_b64 v[8:9], v46, s[58:59] offset:32 glc
	global_load_b64 v[0:1], v46, s[58:59] offset:40
	s_mov_b32 s0, exec_lo
	v_dual_mov_b32 v6, s60 :: v_dual_mov_b32 v7, s61
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v1, s61, v1
	v_and_b32_e32 v0, s60, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v2, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v2, v1
	v_add_co_u32 v4, vcc_lo, v72, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v5, vcc_lo, v73, v1, vcc_lo
	global_store_b64 v[4:5], v[8:9], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v46, v[6:9], s[58:59] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmpx_ne_u64_e64 v[2:3], v[8:9]
	s_cbranch_execz .LBB3_24
; %bb.22:                               ; %.preheader6
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_mov_b32 s1, 0
.LBB3_23:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_6 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	v_dual_mov_b32 v0, s60 :: v_dual_mov_b32 v1, s61
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB3_23
.LBB3_24:                               ; %Flow84
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	global_load_b64 v[0:1], v46, s[58:59] offset:16
	v_dual_mov_b32 v31, v40 :: v_dual_mov_b32 v2, 1
	v_dual_mov_b32 v3, 0 :: v_dual_mov_b32 v4, 3
	s_mov_b64 s[4:5], s[40:41]
	s_mov_b64 s[6:7], s[36:37]
	s_mov_b64 s[8:9], s[34:35]
	s_mov_b64 s[10:11], s[38:39]
	s_mov_b32 s12, s45
	s_mov_b32 s13, s44
	s_mov_b32 s14, s43
	s_mov_b32 s15, s42
	s_swappc_b64 s[30:31], s[54:55]
.LBB3_25:                               ; %Flow85
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s49
	s_add_i32 s72, s72, s71
	v_add_co_u32 v0, vcc_lo, v72, s73
	v_add_co_ci_u32_e32 v1, vcc_lo, s72, v73, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v0, 20
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v1, vcc_lo
.LBB3_26:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_6 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	v_mov_b32_e32 v2, 1
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_28
; %bb.27:                               ;   in Loop: Header=BB3_26 Depth=4
	global_load_b32 v2, v[0:1], off glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_and_b32_e32 v2, 1, v2
.LBB3_28:                               ;   in Loop: Header=BB3_26 Depth=4
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_readfirstlane_b32 s0, v2
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB3_30
; %bb.29:                               ;   in Loop: Header=BB3_26 Depth=4
	s_mov_b32 s0, 0
	s_sleep 1
	s_branch .LBB3_31
.LBB3_30:                               ;   in Loop: Header=BB3_26 Depth=4
	s_mov_b32 s0, -1
.LBB3_31:                               ; %Flow81
                                        ;   in Loop: Header=BB3_26 Depth=4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_26
; %bb.32:                               ;   in Loop: Header=BB3_6 Depth=3
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_36
; %bb.33:                               ;   in Loop: Header=BB3_6 Depth=3
	s_clause 0x2
	global_load_b64 v[2:3], v46, s[58:59] offset:40
	global_load_b64 v[6:7], v46, s[58:59] offset:24 glc
	global_load_b64 v[4:5], v46, s[58:59]
	s_waitcnt vmcnt(2)
	v_add_co_u32 v8, vcc_lo, v2, 1
	v_add_co_ci_u32_e32 v9, vcc_lo, 0, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v8, s60
	v_add_co_ci_u32_e32 v1, vcc_lo, s61, v9, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_eq_u64_e32 vcc_lo, 0, v[0:1]
	v_dual_cndmask_b32 v1, v1, v9 :: v_dual_cndmask_b32 v0, v0, v8
	v_and_b32_e32 v3, v1, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v2, v0, v2
	v_mul_hi_u32 v8, v2, 24
	v_mul_lo_u32 v2, v2, 24
	s_waitcnt vmcnt(0)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_add_co_u32 v4, vcc_lo, v4, v2
	v_mov_b32_e32 v2, v6
	v_mul_lo_u32 v3, v3, 24
	v_add_nc_u32_e32 v3, v8, v3
	s_delay_alu instid0(VALU_DEP_1)
	v_add_co_ci_u32_e32 v5, vcc_lo, v5, v3, vcc_lo
	v_mov_b32_e32 v3, v7
	global_store_b64 v[4:5], v[6:7], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, v[2:3], v[6:7]
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_36
; %bb.34:                               ; %.preheader5
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_mov_b32 s1, 0
.LBB3_35:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_6 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[6:7], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[6:7], v[2:3]
	v_dual_mov_b32 v2, v6 :: v_dual_mov_b32 v3, v7
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB3_35
.LBB3_36:                               ; %__ockl_hostcall_internal.exit1
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_mbcnt_lo_u32_b32 v0, exec_lo, 0
	s_lshl_b32 s1, s66, 2
	s_mov_b32 s0, exec_lo
	v_lshlrev_b32_e32 v2, 2, v0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	s_clause 0x1
	global_store_b64 v[76:77], v[0:1], off offset:8
	global_store_b32 v[76:77], v46, off offset:16
	v_add3_u32 v2, v78, v2, s1
	ds_store_b32 v2, v93
.LBB3_37:                               ; %Flow89
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s70
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s0, s0, exec_lo
.LBB3_38:                               ; %Flow92
                                        ;   in Loop: Header=BB3_6 Depth=3
	s_or_b32 exec_lo, exec_lo, s69
	v_cndmask_b32_e64 v0, 0, 1, s0
	s_add_i32 s67, s67, 32
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_cmp_ne_u32_e32 vcc_lo, 0, v0
	s_bcnt1_i32_b32 s0, vcc_lo
	s_add_i32 s66, s0, s66
	s_cmp_lt_u32 s67, s62
	s_cselect_b32 s69, -1, 0
	s_cmp_lt_u32 s66, 32
	s_cselect_b32 s0, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b32 s0, s69, s0
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_6
.LBB3_39:                               ;   in Loop: Header=BB3_5 Depth=2
	s_cmp_eq_u32 s66, 0
	s_cbranch_scc1 .LBB3_97
; %bb.40:                               ;   in Loop: Header=BB3_5 Depth=2
	s_cmp_ge_u32 s65, s62
	s_cselect_b32 s0, -1, 0
	s_cmp_gt_u32 s68, 31
	s_cselect_b32 s1, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s0, s0, s1
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_80
.LBB3_41:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ; =>    This Loop Header: Depth=3
                                        ;         Child Loop BB3_51 Depth 4
                                        ;         Child Loop BB3_59 Depth 4
                                        ;         Child Loop BB3_62 Depth 4
                                        ;         Child Loop BB3_71 Depth 4
	v_add_nc_u32_e32 v0, s65, v47
	s_mov_b32 s0, 0
	s_mov_b32 s70, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_cmpx_gt_u32_e64 s62, v0
	s_cbranch_execz .LBB3_77
; %bb.42:                               ;   in Loop: Header=BB3_41 Depth=3
	s_mov_b32 s0, exec_lo
                                        ; implicit-def: $vgpr76_vgpr77
	v_cmpx_gt_u32_e32 0x100, v0
	s_xor_b32 s0, exec_lo, s0
; %bb.43:                               ;   in Loop: Header=BB3_41 Depth=3
	s_add_u32 s1, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s1, 0x2800
	s_addc_u32 s3, s3, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mad_u64_u32 v[76:77], null, v0, 24, s[2:3]
; %bb.44:                               ; %Flow72
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_and_not1_saveexec_b32 s0, s0
	s_cbranch_execz .LBB3_46
; %bb.45:                               ;   in Loop: Header=BB3_41 Depth=3
	v_add_nc_u32_e32 v1, 0xffffff00, v0
	s_add_u32 s1, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s1, 0x2800
	s_addc_u32 s3, s3, 0
	v_lshrrev_b32_e32 v3, 8, v1
	s_delay_alu instid0(VALU_DEP_1)
	v_mad_u64_u32 v[1:2], null, v3, 24, s[2:3]
	v_and_b32_e32 v3, 0xff, v0
	global_load_b64 v[1:2], v[1:2], off glc
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[76:77], null, v3, 24, v[1:2]
.LBB3_46:                               ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	s_clause 0x1
	global_load_b64 v[60:61], v[76:77], off offset:8 glc
	global_load_b32 v1, v[76:77], off offset:16 glc
	s_waitcnt vmcnt(1)
	v_cmp_lt_u64_e32 vcc_lo, v[60:61], v[43:44]
	v_cmp_ge_u64_e64 s0, v[60:61], v[41:42]
	s_waitcnt vmcnt(0)
	v_cmp_eq_u32_e64 s1, 0, v1
	s_delay_alu instid0(VALU_DEP_2)
	s_or_b32 s0, vcc_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	s_and_b32 s1, s1, s0
                                        ; implicit-def: $sgpr0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_saveexec_b32 s2, s1
	s_xor_b32 s71, exec_lo, s2
	s_cbranch_execz .LBB3_74
; %bb.47:                               ;   in Loop: Header=BB3_41 Depth=3
	s_mov_b32 s72, exec_lo
	v_cmpx_ne_u64_e32 0, v[60:61]
	s_cbranch_execz .LBB3_73
; %bb.48:                               ;   in Loop: Header=BB3_41 Depth=3
	s_load_b64 s[58:59], s[34:35], 0x50
	v_dual_mov_b32 v45, v47 :: v_dual_mov_b32 v0, 0
	;;#ASMSTART
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_readfirstlane_b32 s0, v45
	v_mov_b32_e32 v1, 0
	v_cmp_eq_u32_e64 s47, s0, v45
	s_delay_alu instid0(VALU_DEP_1)
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_54
; %bb.49:                               ;   in Loop: Header=BB3_41 Depth=3
	s_waitcnt lgkmcnt(0)
	global_load_b64 v[2:3], v46, s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	s_clause 0x1
	global_load_b64 v[0:1], v46, s[58:59] offset:40
	global_load_b64 v[4:5], v46, s[58:59]
	s_mov_b32 s1, exec_lo
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v1, v1, v3
	v_and_b32_e32 v0, v0, v2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v6, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v6, v1
	s_waitcnt vmcnt(0)
	v_add_co_u32 v0, vcc_lo, v4, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v1, vcc_lo, v5, v1, vcc_lo
	global_load_b64 v[0:1], v[0:1], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmpx_ne_u64_e64 v[0:1], v[2:3]
	s_cbranch_execz .LBB3_53
; %bb.50:                               ; %.preheader3
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_mov_b32 s2, 0
.LBB3_51:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_41 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	s_sleep 1
	s_clause 0x1
	global_load_b64 v[4:5], v46, s[58:59] offset:40
	global_load_b64 v[6:7], v46, s[58:59]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_waitcnt vmcnt(1)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_and_b32_e32 v4, v4, v2
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[0:1], null, v4, 24, v[6:7]
	v_and_b32_e32 v6, v5, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mad_u64_u32 v[4:5], null, v6, 24, v[1:2]
	v_mov_b32_e32 v1, v4
	global_load_b64 v[0:1], v[0:1], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB3_51
; %bb.52:                               ; %Flow63
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s2
.LBB3_53:                               ; %Flow65
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
.LBB3_54:                               ;   in Loop: Header=BB3_41 Depth=3
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s0
	s_waitcnt lgkmcnt(0)
	s_clause 0x1
	global_load_b64 v[2:3], v46, s[58:59] offset:40
	global_load_b128 v[72:75], v46, s[58:59]
	v_readfirstlane_b32 s60, v0
	v_readfirstlane_b32 s61, v1
	s_mov_b64 s[0:1], exec
	s_waitcnt vmcnt(1)
	v_readfirstlane_b32 s2, v2
	v_readfirstlane_b32 s3, v3
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[60:61], s[2:3]
	s_mul_i32 s73, s3, 24
	s_mul_hi_u32 s74, s2, 24
	s_mul_i32 s75, s2, 24
	s_and_saveexec_b32 s4, s47
	s_cbranch_execz .LBB3_56
; %bb.55:                               ;   in Loop: Header=BB3_41 Depth=3
	s_add_i32 s5, s74, s73
	s_waitcnt vmcnt(0)
	v_add_co_u32 v0, vcc_lo, v72, s75
	v_add_co_ci_u32_e32 v1, vcc_lo, s5, v73, vcc_lo
	v_dual_mov_b32 v57, s1 :: v_dual_mov_b32 v56, s0
	global_store_b128 v[0:1], v[56:59], off offset:8
.LBB3_56:                               ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s4
	s_lshl_b64 s[0:1], s[2:3], 12
	v_lshlrev_b64 v[0:1], 6, v[45:46]
	s_waitcnt vmcnt(0)
	v_add_co_u32 v2, vcc_lo, v74, s0
	v_add_co_ci_u32_e32 v3, vcc_lo, s1, v75, vcc_lo
	s_mov_b32 s49, s48
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_u32 v4, vcc_lo, v2, v0
	s_mov_b32 s50, s48
	s_mov_b32 s51, s48
	v_add_co_ci_u32_e32 v5, vcc_lo, v3, v1, vcc_lo
	v_dual_mov_b32 v63, v62 :: v_dual_mov_b32 v0, s48
	v_dual_mov_b32 v1, s49 :: v_dual_mov_b32 v2, s50
	v_mov_b32_e32 v3, s51
	s_clause 0x3
	global_store_b128 v[4:5], v[60:63], off
	global_store_b128 v[4:5], v[0:3], off offset:16
	global_store_b128 v[4:5], v[0:3], off offset:32
	global_store_b128 v[4:5], v[0:3], off offset:48
	s_and_saveexec_b32 s49, s47
	s_cbranch_execz .LBB3_61
; %bb.57:                               ;   in Loop: Header=BB3_41 Depth=3
	s_clause 0x1
	global_load_b64 v[8:9], v46, s[58:59] offset:32 glc
	global_load_b64 v[0:1], v46, s[58:59] offset:40
	s_mov_b32 s0, exec_lo
	v_dual_mov_b32 v6, s60 :: v_dual_mov_b32 v7, s61
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v1, s61, v1
	v_and_b32_e32 v0, s60, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v2, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v2, v1
	v_add_co_u32 v4, vcc_lo, v72, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v5, vcc_lo, v73, v1, vcc_lo
	global_store_b64 v[4:5], v[8:9], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v46, v[6:9], s[58:59] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmpx_ne_u64_e64 v[2:3], v[8:9]
	s_cbranch_execz .LBB3_60
; %bb.58:                               ; %.preheader2
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_mov_b32 s1, 0
.LBB3_59:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_41 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	v_dual_mov_b32 v0, s60 :: v_dual_mov_b32 v1, s61
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[0:1], v46, v[0:3], s[58:59] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB3_59
.LBB3_60:                               ; %Flow61
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	global_load_b64 v[0:1], v46, s[58:59] offset:16
	v_dual_mov_b32 v31, v40 :: v_dual_mov_b32 v2, 1
	v_dual_mov_b32 v3, 0 :: v_dual_mov_b32 v4, 3
	s_mov_b64 s[4:5], s[40:41]
	s_mov_b64 s[6:7], s[36:37]
	s_mov_b64 s[8:9], s[34:35]
	s_mov_b64 s[10:11], s[38:39]
	s_mov_b32 s12, s45
	s_mov_b32 s13, s44
	s_mov_b32 s14, s43
	s_mov_b32 s15, s42
	s_swappc_b64 s[30:31], s[54:55]
.LBB3_61:                               ; %Flow62
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s49
	s_add_i32 s74, s74, s73
	v_add_co_u32 v0, vcc_lo, v72, s75
	v_add_co_ci_u32_e32 v1, vcc_lo, s74, v73, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v0, 20
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v1, vcc_lo
.LBB3_62:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_41 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	v_mov_b32_e32 v2, 1
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_64
; %bb.63:                               ;   in Loop: Header=BB3_62 Depth=4
	global_load_b32 v2, v[0:1], off glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_and_b32_e32 v2, 1, v2
.LBB3_64:                               ;   in Loop: Header=BB3_62 Depth=4
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_readfirstlane_b32 s0, v2
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB3_66
; %bb.65:                               ;   in Loop: Header=BB3_62 Depth=4
	s_mov_b32 s0, 0
	s_sleep 1
	s_branch .LBB3_67
.LBB3_66:                               ;   in Loop: Header=BB3_62 Depth=4
	s_mov_b32 s0, -1
.LBB3_67:                               ; %Flow58
                                        ;   in Loop: Header=BB3_62 Depth=4
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_62
; %bb.68:                               ;   in Loop: Header=BB3_41 Depth=3
	s_and_saveexec_b32 s0, s47
	s_cbranch_execz .LBB3_72
; %bb.69:                               ;   in Loop: Header=BB3_41 Depth=3
	s_clause 0x2
	global_load_b64 v[2:3], v46, s[58:59] offset:40
	global_load_b64 v[6:7], v46, s[58:59] offset:24 glc
	global_load_b64 v[4:5], v46, s[58:59]
	s_waitcnt vmcnt(2)
	v_add_co_u32 v8, vcc_lo, v2, 1
	v_add_co_ci_u32_e32 v9, vcc_lo, 0, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v8, s60
	v_add_co_ci_u32_e32 v1, vcc_lo, s61, v9, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_eq_u64_e32 vcc_lo, 0, v[0:1]
	v_dual_cndmask_b32 v1, v1, v9 :: v_dual_cndmask_b32 v0, v0, v8
	v_and_b32_e32 v3, v1, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_and_b32_e32 v2, v0, v2
	v_mul_hi_u32 v8, v2, 24
	v_mul_lo_u32 v2, v2, 24
	s_waitcnt vmcnt(0)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_add_co_u32 v4, vcc_lo, v4, v2
	v_mov_b32_e32 v2, v6
	v_mul_lo_u32 v3, v3, 24
	v_add_nc_u32_e32 v3, v8, v3
	s_delay_alu instid0(VALU_DEP_1)
	v_add_co_ci_u32_e32 v5, vcc_lo, v5, v3, vcc_lo
	v_mov_b32_e32 v3, v7
	global_store_b64 v[4:5], v[6:7], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, v[2:3], v[6:7]
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB3_72
; %bb.70:                               ; %.preheader
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_mov_b32 s1, 0
.LBB3_71:                               ;   Parent Loop BB3_1 Depth=1
                                        ;     Parent Loop BB3_5 Depth=2
                                        ;       Parent Loop BB3_41 Depth=3
                                        ; =>      This Inner Loop Header: Depth=4
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[6:7], v46, v[0:3], s[58:59] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[6:7], v[2:3]
	v_dual_mov_b32 v2, v6 :: v_dual_mov_b32 v3, v7
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB3_71
.LBB3_72:                               ; %__ockl_hostcall_internal.exit
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s0
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v1, 0
	s_clause 0x1
	global_store_b64 v[76:77], v[0:1], off offset:8
	global_store_b32 v[76:77], v46, off offset:16
.LBB3_73:                               ; %Flow67
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s72
	s_mov_b32 s0, 0
                                        ; implicit-def: $vgpr0
.LBB3_74:                               ; %Flow69
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_and_not1_saveexec_b32 s1, s71
	s_cbranch_execz .LBB3_76
; %bb.75:                               ;   in Loop: Header=BB3_41 Depth=3
	v_mbcnt_lo_u32_b32 v1, exec_lo, 0
	s_lshl_b32 s2, s68, 2
	s_or_b32 s0, s0, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_lshlrev_b32_e32 v1, 2, v1
	v_add3_u32 v1, v79, v1, s2
	ds_store_b32 v1, v0
.LBB3_76:                               ; %Flow70
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 s0, s0, exec_lo
.LBB3_77:                               ; %Flow73
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s70
	v_cndmask_b32_e64 v0, 0, 1, s0
	s_mov_b32 s1, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(SALU_CYCLE_1)
	v_cmp_ne_u32_e32 vcc_lo, 0, v0
	s_bcnt1_i32_b32 s0, vcc_lo
	v_cmpx_gt_u32_e64 s0, v47
	s_cbranch_execz .LBB3_79
; %bb.78:                               ;   in Loop: Header=BB3_41 Depth=3
	v_lshl_add_u32 v0, s68, 2, v90
	v_add_lshl_u32 v2, s0, v91, 2
	ds_load_b32 v1, v0
	s_waitcnt lgkmcnt(0)
	ds_bpermute_b32 v1, v2, v1
	s_waitcnt lgkmcnt(0)
	ds_store_b32 v0, v1
.LBB3_79:                               ; %.exit
                                        ;   in Loop: Header=BB3_41 Depth=3
	s_or_b32 exec_lo, exec_lo, s1
	s_sub_i32 s65, s65, 32
	s_add_i32 s68, s0, s68
	s_cmp_lt_u32 s65, s62
	s_cselect_b32 s0, -1, 0
	s_cmp_lt_u32 s68, 32
	s_cselect_b32 s1, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b32 s0, s0, s1
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB3_41
.LBB3_80:                               ;   in Loop: Header=BB3_5 Depth=2
	s_cmp_eq_u32 s68, 0
	s_cbranch_scc1 .LBB3_98
; %bb.81:                               ;   in Loop: Header=BB3_5 Depth=2
	v_min3_u32 v0, s66, s68, 32
	s_mov_b32 s1, 0
	s_mov_b32 s2, exec_lo
	s_delay_alu instid0(VALU_DEP_1)
	v_readfirstlane_b32 s0, v0
	v_cmpx_gt_u32_e64 v0, v47
	s_cbranch_execz .LBB3_83
; %bb.82:                               ;   in Loop: Header=BB3_5 Depth=2
	ds_load_b32 v0, v89
	ds_load_b32 v1, v90
	s_waitcnt lgkmcnt(0)
	v_cmp_lt_u32_e32 vcc_lo, v0, v1
	s_and_b32 s1, vcc_lo, exec_lo
.LBB3_83:                               ;   in Loop: Header=BB3_5 Depth=2
	s_or_b32 exec_lo, exec_lo, s2
	s_and_saveexec_b32 s2, s1
	s_cbranch_execz .LBB3_93
; %bb.84:                               ;   in Loop: Header=BB3_5 Depth=2
	ds_load_b32 v4, v89
	s_mov_b32 s3, exec_lo
                                        ; implicit-def: $vgpr0_vgpr1
	s_waitcnt lgkmcnt(0)
	v_cmpx_gt_u32_e32 0x100, v4
	s_xor_b32 s3, exec_lo, s3
; %bb.85:                               ;   in Loop: Header=BB3_5 Depth=2
	s_add_u32 s4, s52, s64
	s_addc_u32 s5, s53, s63
	s_add_u32 s4, s4, 0x2800
	s_addc_u32 s5, s5, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mad_u64_u32 v[0:1], null, v4, 24, s[4:5]
; %bb.86:                               ; %Flow53
                                        ;   in Loop: Header=BB3_5 Depth=2
	s_and_not1_saveexec_b32 s3, s3
	s_cbranch_execz .LBB3_88
; %bb.87:                               ;   in Loop: Header=BB3_5 Depth=2
	v_add_nc_u32_e32 v0, 0xffffff00, v4
	s_add_u32 s4, s52, s64
	s_addc_u32 s5, s53, s63
	s_add_u32 s4, s4, 0x2800
	s_addc_u32 s5, s5, 0
	v_lshrrev_b32_e32 v2, 8, v0
	v_and_b32_e32 v5, 0xff, v4
	s_delay_alu instid0(VALU_DEP_2)
	v_mad_u64_u32 v[0:1], null, v2, 24, s[4:5]
	global_load_b64 v[2:3], v[0:1], off glc
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[0:1], null, v5, 24, v[2:3]
.LBB3_88:                               ;   in Loop: Header=BB3_5 Depth=2
	s_or_b32 exec_lo, exec_lo, s3
	ds_load_b32 v5, v90
	s_mov_b32 s3, exec_lo
                                        ; implicit-def: $vgpr2_vgpr3
	s_waitcnt lgkmcnt(0)
	v_cmpx_gt_u32_e32 0x100, v5
	s_xor_b32 s3, exec_lo, s3
; %bb.89:                               ;   in Loop: Header=BB3_5 Depth=2
	s_add_u32 s4, s52, s64
	s_addc_u32 s5, s53, s63
	s_add_u32 s4, s4, 0x2800
	s_addc_u32 s5, s5, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mad_u64_u32 v[2:3], null, v5, 24, s[4:5]
                                        ; implicit-def: $vgpr5
; %bb.90:                               ; %Flow52
                                        ;   in Loop: Header=BB3_5 Depth=2
	s_and_not1_saveexec_b32 s3, s3
	s_cbranch_execz .LBB3_92
; %bb.91:                               ;   in Loop: Header=BB3_5 Depth=2
	v_add_nc_u32_e32 v2, 0xffffff00, v5
	s_add_u32 s4, s52, s64
	s_addc_u32 s5, s53, s63
	s_add_u32 s4, s4, 0x2800
	s_addc_u32 s5, s5, 0
	v_lshrrev_b32_e32 v6, 8, v2
	v_and_b32_e32 v5, 0xff, v5
	s_delay_alu instid0(VALU_DEP_2)
	v_mad_u64_u32 v[2:3], null, v6, 24, s[4:5]
	global_load_b64 v[6:7], v[2:3], off glc
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[2:3], null, v5, 24, v[6:7]
.LBB3_92:                               ;   in Loop: Header=BB3_5 Depth=2
	s_or_b32 exec_lo, exec_lo, s3
	global_load_b64 v[5:6], v[2:3], off offset:8 glc
	s_waitcnt vmcnt(0)
	global_store_b32 v[5:6], v4, off offset:4
	global_store_b64 v[0:1], v[5:6], off offset:8
	global_load_b32 v6, v[2:3], off offset:16 glc
	v_mov_b32_e32 v4, 0
	v_mov_b32_e32 v5, 0
	s_waitcnt vmcnt(0)
	global_store_b32 v[0:1], v6, off offset:16
	s_clause 0x1
	global_store_b64 v[2:3], v[4:5], off offset:8
	global_store_b32 v[2:3], v46, off offset:16
.LBB3_93:                               ; %Flow54
                                        ;   in Loop: Header=BB3_5 Depth=2
	s_or_b32 exec_lo, exec_lo, s2
	v_cndmask_b32_e64 v0, 0, 1, s1
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_ne_u32_e32 vcc_lo, 0, v0
	s_bcnt1_i32_b32 s1, vcc_lo
	s_cbranch_vccz .LBB3_95
; %bb.94:                               ;   in Loop: Header=BB3_5 Depth=2
	v_lshl_add_u32 v0, s1, 2, v88
	s_waitcnt lgkmcnt(0)
	ds_load_b32 v92, v0
.LBB3_95:                               ;   in Loop: Header=BB3_5 Depth=2
	s_cmp_lg_u32 s1, s0
	s_cselect_b32 s1, -1, 0
	s_xor_b32 s2, s69, -1
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_or_b32 s1, s2, s1
	s_and_b32 vcc_lo, exec_lo, s1
	s_cbranch_vccnz .LBB3_99
; %bb.96:                               ;   in Loop: Header=BB3_5 Depth=2
	s_lshl_b32 s2, s0, 2
	s_sub_i32 s66, s66, s0
	v_add_nc_u32_e32 v0, s2, v89
	v_add_nc_u32_e32 v1, s2, v90
	s_sub_i32 s68, s68, s0
	ds_load_b32 v0, v0
	ds_load_b32 v1, v1
	s_waitcnt lgkmcnt(1)
	ds_store_b32 v89, v0
	s_waitcnt lgkmcnt(1)
	ds_store_b32 v90, v1
	s_branch .LBB3_99
.LBB3_97:                               ;   in Loop: Header=BB3_5 Depth=2
	s_mov_b32 s1, -1
                                        ; implicit-def: $sgpr67
                                        ; implicit-def: $sgpr68
                                        ; implicit-def: $sgpr65
                                        ; implicit-def: $sgpr66
	s_branch .LBB3_99
.LBB3_98:                               ;   in Loop: Header=BB3_5 Depth=2
	s_mov_b32 s1, -1
                                        ; implicit-def: $sgpr67
                                        ; implicit-def: $sgpr68
                                        ; implicit-def: $sgpr65
                                        ; implicit-def: $sgpr66
.LBB3_99:                               ; %Flow99
                                        ;   in Loop: Header=BB3_5 Depth=2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_b32 vcc_lo, exec_lo, s1
	s_cbranch_vccz .LBB3_5
; %bb.100:                              ;   in Loop: Header=BB3_1 Depth=1
	s_waitcnt lgkmcnt(0)
	v_and_b32_e32 v2, 0xffffffe0, v92
.LBB3_101:                              ;   Parent Loop BB3_1 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_add_nc_u32_e32 v3, v2, v47
	s_mov_b32 s1, 0
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_u32_e64 s62, v3
	s_cbranch_execz .LBB3_107
; %bb.102:                              ;   in Loop: Header=BB3_101 Depth=2
	s_mov_b32 s1, exec_lo
                                        ; implicit-def: $vgpr0_vgpr1
	v_cmpx_gt_u32_e32 0x100, v3
	s_xor_b32 s1, exec_lo, s1
; %bb.103:                              ;   in Loop: Header=BB3_101 Depth=2
	s_add_u32 s2, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s2, 0x2800
	s_addc_u32 s3, s3, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	v_mad_u64_u32 v[0:1], null, v3, 24, s[2:3]
                                        ; implicit-def: $vgpr3
; %bb.104:                              ; %Flow50
                                        ;   in Loop: Header=BB3_101 Depth=2
	s_and_not1_saveexec_b32 s1, s1
	s_cbranch_execz .LBB3_106
; %bb.105:                              ;   in Loop: Header=BB3_101 Depth=2
	v_add_nc_u32_e32 v0, 0xffffff00, v3
	s_add_u32 s2, s52, s64
	s_addc_u32 s3, s53, s63
	s_add_u32 s2, s2, 0x2800
	s_addc_u32 s3, s3, 0
	v_lshrrev_b32_e32 v4, 8, v0
	v_and_b32_e32 v3, 0xff, v3
	s_delay_alu instid0(VALU_DEP_2)
	v_mad_u64_u32 v[0:1], null, v4, 24, s[2:3]
	global_load_b64 v[4:5], v[0:1], off glc
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[0:1], null, v3, 24, v[4:5]
.LBB3_106:                              ;   in Loop: Header=BB3_101 Depth=2
	s_or_b32 exec_lo, exec_lo, s1
	global_load_b64 v[0:1], v[0:1], off offset:8 glc
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, 0, v[0:1]
	s_and_b32 s1, vcc_lo, exec_lo
.LBB3_107:                              ; %Flow51
                                        ;   in Loop: Header=BB3_101 Depth=2
	s_or_b32 exec_lo, exec_lo, s0
	v_cndmask_b32_e64 v0, 0, 1, s1
	s_delay_alu instid0(VALU_DEP_1)
	v_cmp_ne_u32_e32 vcc_lo, 0, v0
	s_bcnt1_i32_b32 s0, vcc_lo
	s_cmp_eq_u32 vcc_lo, -1
	v_add_nc_u32_e32 v2, s0, v2
	s_cbranch_scc1 .LBB3_101
; %bb.108:                              ;   in Loop: Header=BB3_1 Depth=1
	s_and_saveexec_b32 s0, s46
	s_cbranch_execz .LBB3_110
; %bb.109:                              ;   in Loop: Header=BB3_1 Depth=1
	s_lshl_b64 s[2:3], s[56:57], 7
	s_delay_alu instid0(SALU_CYCLE_1)
	s_add_u32 s2, s52, s2
	s_addc_u32 s3, s53, s3
	global_store_b32 v46, v2, s[2:3] offset:2048
.LBB3_110:                              ; %Flow
                                        ;   in Loop: Header=BB3_1 Depth=1
	s_or_b32 exec_lo, exec_lo, s0
.LBB3_111:                              ;   in Loop: Header=BB3_1 Depth=1
	s_add_i32 s56, s56, 1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_cmp_eq_u32 s56, 16
	s_cbranch_scc0 .LBB3_1
; %bb.112:
	s_clause 0x1d
	scratch_load_b32 v93, off, s33
	scratch_load_b32 v92, off, s33 offset:4
	scratch_load_b32 v91, off, s33 offset:8
	scratch_load_b32 v90, off, s33 offset:12
	scratch_load_b32 v89, off, s33 offset:16
	scratch_load_b32 v88, off, s33 offset:20
	scratch_load_b32 v79, off, s33 offset:24
	scratch_load_b32 v78, off, s33 offset:28
	scratch_load_b32 v77, off, s33 offset:32
	scratch_load_b32 v76, off, s33 offset:36
	scratch_load_b32 v75, off, s33 offset:40
	scratch_load_b32 v74, off, s33 offset:44
	scratch_load_b32 v73, off, s33 offset:48
	scratch_load_b32 v72, off, s33 offset:52
	scratch_load_b32 v63, off, s33 offset:56
	scratch_load_b32 v62, off, s33 offset:60
	scratch_load_b32 v61, off, s33 offset:64
	scratch_load_b32 v60, off, s33 offset:68
	scratch_load_b32 v59, off, s33 offset:72
	scratch_load_b32 v58, off, s33 offset:76
	scratch_load_b32 v57, off, s33 offset:80
	scratch_load_b32 v56, off, s33 offset:84
	scratch_load_b32 v47, off, s33 offset:88
	scratch_load_b32 v46, off, s33 offset:92
	scratch_load_b32 v45, off, s33 offset:96
	scratch_load_b32 v44, off, s33 offset:100
	scratch_load_b32 v43, off, s33 offset:104
	scratch_load_b32 v42, off, s33 offset:108
	scratch_load_b32 v41, off, s33 offset:112
	scratch_load_b32 v40, off, s33 offset:116
	v_readlane_b32 s75, v95, 11
	v_readlane_b32 s74, v95, 10
	v_readlane_b32 s73, v95, 9
	v_readlane_b32 s72, v95, 8
	v_readlane_b32 s71, v95, 7
	v_readlane_b32 s70, v95, 6
	v_readlane_b32 s69, v95, 5
	v_readlane_b32 s68, v95, 4
	v_readlane_b32 s67, v95, 3
	v_readlane_b32 s66, v95, 2
	v_readlane_b32 s65, v95, 1
	v_readlane_b32 s64, v95, 0
	v_readlane_b32 s63, v94, 31
	v_readlane_b32 s62, v94, 30
	v_readlane_b32 s61, v94, 29
	v_readlane_b32 s60, v94, 28
	v_readlane_b32 s59, v94, 27
	v_readlane_b32 s58, v94, 26
	v_readlane_b32 s57, v94, 25
	v_readlane_b32 s56, v94, 24
	v_readlane_b32 s55, v94, 23
	v_readlane_b32 s54, v94, 22
	v_readlane_b32 s53, v94, 21
	v_readlane_b32 s52, v94, 20
	v_readlane_b32 s51, v94, 19
	v_readlane_b32 s50, v94, 18
	v_readlane_b32 s49, v94, 17
	v_readlane_b32 s48, v94, 16
	v_readlane_b32 s47, v94, 15
	v_readlane_b32 s46, v94, 14
	v_readlane_b32 s45, v94, 13
	v_readlane_b32 s44, v94, 12
	v_readlane_b32 s43, v94, 11
	v_readlane_b32 s42, v94, 10
	v_readlane_b32 s41, v94, 9
	v_readlane_b32 s40, v94, 8
	v_readlane_b32 s39, v94, 7
	v_readlane_b32 s38, v94, 6
	v_readlane_b32 s37, v94, 5
	v_readlane_b32 s36, v94, 4
	v_readlane_b32 s35, v94, 3
	v_readlane_b32 s34, v94, 2
	v_readlane_b32 s31, v94, 1
	v_readlane_b32 s30, v94, 0
	v_readlane_b32 s0, v95, 12
	s_or_saveexec_b32 s1, -1
	s_clause 0x1
	scratch_load_b32 v94, off, s33 offset:120
	scratch_load_b32 v95, off, s33 offset:124
	s_mov_b32 exec_lo, s1
	s_addk_i32 s32, 0xff70
	s_mov_b32 s33, s0
	s_waitcnt vmcnt(0)
	s_setpc_b64 s[30:31]
.Lfunc_end4:
	.size	__ockl_dm_trim, .Lfunc_end4-__ockl_dm_trim
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 5948
; NumSgprs: 78
; NumVgprs: 96
; ScratchSize: 144
; MemoryBound: 0
	.text
	.protected	__ockl_sanitizer_report ; -- Begin function __ockl_sanitizer_report
	.weak	__ockl_sanitizer_report
	.p2align	2
	.type	__ockl_sanitizer_report,@function
__ockl_sanitizer_report:                ; @__ockl_sanitizer_report
.Lfunc_begin5:
	.cfi_startproc
; %bb.0:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
	s_mov_b32 s0, s33
	s_mov_b32 s33, s32
	s_or_saveexec_b32 s1, -1
	scratch_store_b32 off, v44, s33 offset:16 ; 4-byte Folded Spill
	s_mov_b32 exec_lo, s1
	v_writelane_b32 v44, s0, 11
	s_clause 0x3
	scratch_store_b32 off, v40, s33 offset:12
	scratch_store_b32 off, v41, s33 offset:8
	scratch_store_b32 off, v42, s33 offset:4
	scratch_store_b32 off, v43, s33
	v_mbcnt_lo_u32_b32 v16, -1, 0
	v_mov_b32_e32 v18, 0
	v_mov_b32_e32 v19, 0
	v_writelane_b32 v44, s30, 0
	s_add_i32 s32, s32, 32
	v_writelane_b32 v44, s31, 1
	v_writelane_b32 v44, s34, 2
	v_writelane_b32 v44, s35, 3
	v_writelane_b32 v44, s36, 4
	v_writelane_b32 v44, s37, 5
	s_load_b64 s[36:37], s[8:9], 0x50
	;;#ASMSTART
	;;#ASMEND
	v_readfirstlane_b32 s0, v16
	v_writelane_b32 v44, s38, 6
	s_delay_alu instid0(VALU_DEP_2)
	v_cmp_eq_u32_e64 s34, s0, v16
	v_writelane_b32 v44, s39, 7
	v_writelane_b32 v44, s40, 8
	v_writelane_b32 v44, s41, 9
	v_writelane_b32 v44, s42, 10
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB4_6
; %bb.1:
	v_mov_b32_e32 v17, 0
	s_mov_b32 s1, exec_lo
	s_waitcnt lgkmcnt(0)
	global_load_b64 v[20:21], v17, s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	s_clause 0x1
	global_load_b64 v[18:19], v17, s[36:37] offset:40
	global_load_b64 v[22:23], v17, s[36:37]
	s_waitcnt vmcnt(1)
	v_and_b32_e32 v18, v18, v20
	v_and_b32_e32 v19, v19, v21
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v24, v18, 24
	v_mul_lo_u32 v19, v19, 24
	v_mul_lo_u32 v18, v18, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v19, v24, v19
	s_waitcnt vmcnt(0)
	v_add_co_u32 v18, vcc_lo, v22, v18
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v19, vcc_lo, v23, v19, vcc_lo
	global_load_b64 v[18:19], v[18:19], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[18:19], v17, v[18:21], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmpx_ne_u64_e64 v[18:19], v[20:21]
	s_cbranch_execz .LBB4_5
; %bb.2:                                ; %.preheader2
	s_mov_b32 s2, 0
	.p2align	6
.LBB4_3:                                ; =>This Inner Loop Header: Depth=1
	s_sleep 1
	s_clause 0x1
	global_load_b64 v[22:23], v17, s[36:37] offset:40
	global_load_b64 v[24:25], v17, s[36:37]
	v_dual_mov_b32 v21, v19 :: v_dual_mov_b32 v20, v18
	s_waitcnt vmcnt(1)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_and_b32_e32 v22, v22, v20
	s_waitcnt vmcnt(0)
	v_mad_u64_u32 v[18:19], null, v22, 24, v[24:25]
	v_and_b32_e32 v24, v23, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mad_u64_u32 v[22:23], null, v24, 24, v[19:20]
	v_mov_b32_e32 v19, v22
	global_load_b64 v[18:19], v[18:19], off glc
	s_waitcnt vmcnt(0)
	global_atomic_cmpswap_b64 v[18:19], v17, v[18:21], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_cmp_eq_u64_e32 vcc_lo, v[18:19], v[20:21]
	s_or_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s2
	s_cbranch_execnz .LBB4_3
; %bb.4:                                ; %Flow22
	s_or_b32 exec_lo, exec_lo, s2
.LBB4_5:                                ; %Flow24
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s1
.LBB4_6:
	s_delay_alu instid0(SALU_CYCLE_1)
	s_or_b32 exec_lo, exec_lo, s0
	v_mov_b32_e32 v17, 0
	v_readfirstlane_b32 s38, v18
	v_readfirstlane_b32 s39, v19
	s_mov_b64 s[0:1], exec
	s_waitcnt lgkmcnt(0)
	s_clause 0x1
	global_load_b64 v[20:21], v17, s[36:37] offset:40
	global_load_b128 v[40:43], v17, s[36:37]
	s_waitcnt vmcnt(1)
	v_readfirstlane_b32 s2, v20
	v_readfirstlane_b32 s3, v21
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_and_b64 s[2:3], s[38:39], s[2:3]
	s_mul_i32 s35, s3, 24
	s_mul_hi_u32 s40, s2, 24
	s_mul_i32 s41, s2, 24
	s_and_saveexec_b32 s16, s34
	s_cbranch_execz .LBB4_8
; %bb.7:
	s_add_i32 s17, s40, s35
	s_waitcnt vmcnt(0)
	v_add_co_u32 v22, vcc_lo, v40, s41
	v_add_co_ci_u32_e32 v23, vcc_lo, s17, v41, vcc_lo
	v_dual_mov_b32 v19, s1 :: v_dual_mov_b32 v18, s0
	v_dual_mov_b32 v20, 4 :: v_dual_mov_b32 v21, 1
	global_store_b128 v[22:23], v[18:21], off offset:8
.LBB4_8:
	s_or_b32 exec_lo, exec_lo, s16
	s_lshl_b64 s[0:1], s[2:3], 12
	v_lshlrev_b64 v[16:17], 6, v[16:17]
	s_waitcnt vmcnt(0)
	v_add_co_u32 v18, vcc_lo, v42, s0
	v_add_co_ci_u32_e32 v19, vcc_lo, s1, v43, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v16, vcc_lo, v18, v16
	v_add_co_ci_u32_e32 v17, vcc_lo, v19, v17, vcc_lo
	s_clause 0x3
	global_store_b128 v[16:17], v[0:3], off
	global_store_b128 v[16:17], v[4:7], off offset:16
	global_store_b128 v[16:17], v[8:11], off offset:32
	global_store_b128 v[16:17], v[12:15], off offset:48
	s_and_saveexec_b32 s42, s34
	s_cbranch_execz .LBB4_13
; %bb.9:
	v_mov_b32_e32 v6, 0
	s_mov_b32 s0, exec_lo
	s_clause 0x1
	global_load_b64 v[9:10], v6, s[36:37] offset:32 glc
	global_load_b64 v[0:1], v6, s[36:37] offset:40
	v_dual_mov_b32 v7, s38 :: v_dual_mov_b32 v8, s39
	s_waitcnt vmcnt(0)
	v_and_b32_e32 v1, s39, v1
	v_and_b32_e32 v0, s38, v0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_mul_lo_u32 v1, v1, 24
	v_mul_hi_u32 v2, v0, 24
	v_mul_lo_u32 v0, v0, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_nc_u32_e32 v1, v2, v1
	v_add_co_u32 v4, vcc_lo, v40, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v5, vcc_lo, v41, v1, vcc_lo
	global_store_b64 v[4:5], v[9:10], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v6, v[7:10], s[36:37] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmpx_ne_u64_e64 v[2:3], v[9:10]
	s_cbranch_execz .LBB4_12
; %bb.10:                               ; %.preheader1
	s_mov_b32 s1, 0
.LBB4_11:                               ; =>This Inner Loop Header: Depth=1
	v_dual_mov_b32 v0, s38 :: v_dual_mov_b32 v1, s39
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[0:1], v6, v[0:3], s[36:37] offset:32 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]
	v_dual_mov_b32 v3, v1 :: v_dual_mov_b32 v2, v0
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB4_11
.LBB4_12:                               ; %Flow20
	s_or_b32 exec_lo, exec_lo, s0
	v_dual_mov_b32 v0, 0 :: v_dual_mov_b32 v3, 0
	v_mov_b32_e32 v2, 1
	v_mov_b32_e32 v4, 3
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, __ockl_hsa_signal_add@rel32@lo+4
	s_addc_u32 s1, s1, __ockl_hsa_signal_add@rel32@hi+12
	global_load_b64 v[0:1], v0, s[36:37] offset:16
	s_swappc_b64 s[30:31], s[0:1]
.LBB4_13:                               ; %Flow21
	s_or_b32 exec_lo, exec_lo, s42
	s_add_i32 s40, s40, s35
	v_add_co_u32 v0, vcc_lo, v40, s41
	v_add_co_ci_u32_e32 v1, vcc_lo, s40, v41, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v0, 20
	v_add_co_ci_u32_e32 v1, vcc_lo, 0, v1, vcc_lo
	s_branch .LBB4_17
	.p2align	6
.LBB4_14:                               ;   in Loop: Header=BB4_17 Depth=1
	s_or_b32 exec_lo, exec_lo, s0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_readfirstlane_b32 s0, v2
	s_cmp_eq_u32 s0, 0
	s_cbranch_scc1 .LBB4_16
; %bb.15:                               ;   in Loop: Header=BB4_17 Depth=1
	s_sleep 1
	s_cbranch_execnz .LBB4_17
	s_branch .LBB4_19
	.p2align	6
.LBB4_16:
	s_branch .LBB4_19
.LBB4_17:                               ; =>This Inner Loop Header: Depth=1
	v_mov_b32_e32 v2, 1
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB4_14
; %bb.18:                               ;   in Loop: Header=BB4_17 Depth=1
	global_load_b32 v2, v[0:1], off glc
	s_waitcnt vmcnt(0)
	buffer_gl0_inv
	buffer_gl1_inv
	v_and_b32_e32 v2, 1, v2
	s_branch .LBB4_14
.LBB4_19:
	s_and_saveexec_b32 s0, s34
	s_cbranch_execz .LBB4_23
; %bb.20:
	v_mov_b32_e32 v6, 0
	s_clause 0x2
	global_load_b64 v[2:3], v6, s[36:37] offset:40
	global_load_b64 v[7:8], v6, s[36:37] offset:24 glc
	global_load_b64 v[4:5], v6, s[36:37]
	s_waitcnt vmcnt(2)
	v_add_co_u32 v9, vcc_lo, v2, 1
	v_add_co_ci_u32_e32 v10, vcc_lo, 0, v3, vcc_lo
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_add_co_u32 v0, vcc_lo, v9, s38
	v_add_co_ci_u32_e32 v1, vcc_lo, s39, v10, vcc_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_cmp_eq_u64_e32 vcc_lo, 0, v[0:1]
	v_dual_cndmask_b32 v1, v1, v10 :: v_dual_cndmask_b32 v0, v0, v9
	v_and_b32_e32 v3, v1, v3
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_and_b32_e32 v2, v0, v2
	v_mul_lo_u32 v3, v3, 24
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_mul_hi_u32 v9, v2, 24
	v_mul_lo_u32 v2, v2, 24
	v_add_nc_u32_e32 v3, v9, v3
	s_waitcnt vmcnt(0)
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_add_co_u32 v4, vcc_lo, v4, v2
	v_mov_b32_e32 v2, v7
	v_add_co_ci_u32_e32 v5, vcc_lo, v5, v3, vcc_lo
	v_mov_b32_e32 v3, v8
	global_store_b64 v[4:5], v[7:8], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[2:3], v6, v[0:3], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_ne_u64_e32 vcc_lo, v[2:3], v[7:8]
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB4_23
; %bb.21:                               ; %.preheader
	s_mov_b32 s1, 0
.LBB4_22:                               ; =>This Inner Loop Header: Depth=1
	s_sleep 1
	global_store_b64 v[4:5], v[2:3], off
	s_waitcnt_vscnt null, 0x0
	global_atomic_cmpswap_b64 v[7:8], v6, v[0:3], s[36:37] offset:24 glc
	s_waitcnt vmcnt(0)
	v_cmp_eq_u64_e32 vcc_lo, v[7:8], v[2:3]
	v_dual_mov_b32 v2, v7 :: v_dual_mov_b32 v3, v8
	s_or_b32 s1, vcc_lo, s1
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_not1_b32 exec_lo, exec_lo, s1
	s_cbranch_execnz .LBB4_22
.LBB4_23:                               ; %__ockl_hostcall_internal.exit
	s_or_b32 exec_lo, exec_lo, s0
	s_clause 0x3
	scratch_load_b32 v43, off, s33
	scratch_load_b32 v42, off, s33 offset:4
	scratch_load_b32 v41, off, s33 offset:8
	scratch_load_b32 v40, off, s33 offset:12
	v_readlane_b32 s42, v44, 10
	v_readlane_b32 s41, v44, 9
	v_readlane_b32 s40, v44, 8
	v_readlane_b32 s39, v44, 7
	v_readlane_b32 s38, v44, 6
	v_readlane_b32 s37, v44, 5
	v_readlane_b32 s36, v44, 4
	v_readlane_b32 s35, v44, 3
	v_readlane_b32 s34, v44, 2
	v_readlane_b32 s31, v44, 1
	v_readlane_b32 s30, v44, 0
	v_readlane_b32 s0, v44, 11
	s_or_saveexec_b32 s1, -1
	scratch_load_b32 v44, off, s33 offset:16 ; 4-byte Folded Reload
	s_mov_b32 exec_lo, s1
	s_addk_i32 s32, 0xffe0
	s_mov_b32 s33, s0
	s_waitcnt vmcnt(0)
	s_setpc_b64 s[30:31]
.Lfunc_end5:
	.size	__ockl_sanitizer_report, .Lfunc_end5-__ockl_sanitizer_report
	.cfi_endproc
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Function info:
; codeLenInByte = 1572
; NumSgprs: 45
; NumVgprs: 45
; ScratchSize: 32
; MemoryBound: 0
	.text
	.globl	_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_ ; -- Begin function _Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_
	.p2align	8
	.type	_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_,@function
_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_: ; @_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_
.Lfunc_begin6:
	.file	2 "." "none"
	.loc	2 0 0                           ; none:0:0
	.cfi_startproc
; %bb.0:                                ; %conversion
	s_load_b64 s[2:3], s[0:1], 0x28
	v_add_nc_u32_e32 v0, 1, v0
	s_mov_b32 s9, 0
	s_mov_b32 s32, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_add_co_u32 v0, s4, v0, s13
	v_add_co_ci_u32_e64 v1, null, 0, 0, s4
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_cmp_eq_u64_e32 vcc_lo, 1, v[0:1]
	s_waitcnt lgkmcnt(0)
	v_cmp_gt_i64_e64 s2, s[2:3], 0
	s_and_b32 s2, vcc_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
	s_and_saveexec_b32 s3, s2
	s_cbranch_execz .LBB6_22
; %bb.1:                                ; %L233
	s_load_b32 s8, s[0:1], 0x60
	s_waitcnt lgkmcnt(0)
	s_cmp_eq_u32 s8, 0
.Ltmp2:
	.file	3 "." "/home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl"
	.loc	3 230 0 prologue_end            ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:230:0
	s_cbranch_scc1 .LBB6_23
; %bb.2:                                ; %L250.preheader
	.loc	3 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:0:0
	s_load_b64 s[2:3], s[0:1], 0x40
	v_mov_b32_e32 v0, 0
	s_mov_b64 s[4:5], 0
.LBB6_3:                                ; %L250
                                        ; =>This Inner Loop Header: Depth=1
	s_delay_alu instid0(SALU_CYCLE_1)
.Ltmp3:
	.file	4 "." "/home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl"
	.loc	4 39 0 is_stmt 1                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_add_u32 s4, s4, 1
	s_addc_u32 s5, s5, 0
	v_mov_b32_e32 v1, s4
	s_waitcnt lgkmcnt(0)
	global_store_b32 v0, v1, s[2:3]
.Ltmp4:
	.file	5 "." "promotion.jl"
	.loc	5 637 0                         ; promotion.jl:637:0
	s_add_u32 s2, s2, 4
	s_addc_u32 s3, s3, 0
	s_cmp_lg_u64 s[8:9], s[4:5]
.Ltmp5:
	.loc	3 232 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:232:0
	s_cbranch_scc1 .LBB6_3
; %bb.4:                                ; %L284
	.loc	3 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:0:0
	s_cmp_eq_u32 s8, 1
	s_mov_b64 s[10:11], 2
	s_cselect_b32 s2, -1, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	.loc	3 230 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:230:0
	s_and_b32 vcc_lo, exec_lo, s2
	s_cbranch_vccz .LBB6_6
.LBB6_5:                                ; %L291
.Ltmp6:
	.file	6 "." "int.jl"
	.loc	6 87 0                          ; int.jl:87:0
	s_add_u32 s10, s8, 1
	s_addc_u32 s11, 0, 0
.Ltmp7:
.LBB6_6:                                ; %L318
	.loc	6 0 0 is_stmt 0                 ; int.jl:0:0
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(VALU_DEP_1)
.Ltmp8:
	.loc	6 83 0 is_stmt 1                ; int.jl:83:0
	v_cmp_gt_i64_e64 s2, s[10:11], s[8:9]
.Ltmp9:
	.loc	3 233 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:233:0
	s_and_b32 vcc_lo, exec_lo, s2
	s_cbranch_vccnz .LBB6_22
; %bb.7:                                ; %L332.preheader
	.loc	3 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:0:0
	s_clause 0x2
	s_load_b128 s[4:7], s[0:1], 0x50
	s_load_b64 s[2:3], s[0:1], 0x0
	s_load_b64 s[0:1], s[0:1], 0x40
	v_mov_b32_e32 v0, 0
	s_mov_b32 s16, 0
	s_mov_b64 s[24:25], s[8:9]
	s_waitcnt lgkmcnt(0)
	s_xor_b32 s5, s5, 0x5a371ba9
	s_xor_b32 s4, s4, 0x73dffbc4
	s_mul_hi_u32 s19, s6, 0xd2511f53
	s_mul_i32 s18, s6, 0xd2511f53
	s_add_i32 s12, s4, 0x9e3779b9
	s_xor_b64 s[20:21], s[18:19], s[4:5]
	s_add_u32 s19, s5, 0xbb67ae85
	s_add_u32 s20, s4, 0x3c6ef372
	s_add_u32 s22, s5, 0x76cf5d0a
	s_addc_u32 s23, 0, 0
	s_add_u32 s28, s4, 0xdaa66d2b
	s_add_u32 s29, s5, 0x32370b8f
	s_add_u32 s30, s4, 0x78dde6e4
	s_add_u32 s31, s5, 0xed9eba14
	s_add_u32 s33, s4, 0x1715609d
	s_add_u32 s34, s5, 0xa9066899
	s_add_u32 s35, s4, 0xb54cda56
	s_add_u32 s36, s5, 0x646e171e
	s_add_u32 s37, s4, 0x5384540f
	s_add_u32 s38, s5, 0x1fd5c5a3
	s_add_u32 s5, s5, 0xdb3d7428
	s_add_i32 s39, s4, 0x8ff34781
.Ltmp10:
	.file	7 "." "/home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl"
	.loc	7 300 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:300:0
	s_add_u32 s40, s0, -4
	s_addc_u32 s41, s1, -1
	s_branch .LBB6_10
.LBB6_8:                                ;   in Loop: Header=BB6_10 Depth=1
	.loc	7 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:0:0
	s_mov_b32 s27, -1
	s_mov_b32 s17, s16
	s_mov_b32 s26, -1
                                        ; implicit-def: $sgpr24_sgpr25
.LBB6_9:                                ; %Flow14
                                        ;   in Loop: Header=BB6_10 Depth=1
	s_delay_alu instid0(SALU_CYCLE_1)
	.loc	7 300 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:300:0
	s_and_b32 vcc_lo, exec_lo, s26
	s_cbranch_vccnz .LBB6_17
.LBB6_10:                               ; %L332
                                        ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB6_13 Depth 2
.Ltmp11:
	.loc	6 519 0 is_stmt 1               ; int.jl:519:0
	s_cmp_lg_u32 s24, 0
	s_cbranch_scc0 .LBB6_8
.Ltmp12:
; %bb.11:                               ; %pass
                                        ;   in Loop: Header=BB6_10 Depth=1
	.loc	6 304 0                         ; int.jl:304:0
	v_cvt_f32_u32_e32 v1, s24
.Ltmp13:
	.loc	6 85 0                          ; int.jl:85:0
	s_sub_i32 s17, 0, s24
	s_mov_b32 s27, s16
.Ltmp14:
	.loc	6 304 0                         ; int.jl:304:0
	s_waitcnt_depctr 0xfff
	v_rcp_iflag_f32_e32 v1, v1
	s_waitcnt_depctr 0xfff
	v_mul_f32_e32 v1, 0x4f7ffffe, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_cvt_u32_f32_e32 v1, v1
	v_readfirstlane_b32 s9, v1
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_mul_i32 s26, s17, s9
	s_mul_hi_u32 s26, s9, s26
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_add_i32 s9, s9, s26
	s_mul_hi_u32 s26, s17, s9
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_mul_i32 s26, s26, s24
	s_sub_i32 s17, s17, s26
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(SALU_CYCLE_1)
	s_sub_i32 s26, s17, s24
	s_cmp_ge_u32 s17, s24
	s_cselect_b32 s17, s26, s17
	s_sub_i32 s26, s17, s24
	s_cmp_ge_u32 s17, s24
	s_cselect_b32 s42, s26, s17
	s_sub_i32 s17, s8, s24
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_lshl_b32 s17, s17, 22
	s_bitset1_b32 s17, 15
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_xor_b32 s17, s17, s21
	s_mul_hi_u32 s26, s17, 0xcd9e8d57
	s_mul_i32 s43, s17, 0xcd9e8d57
	s_xor_b32 s44, s26, s12
	s_delay_alu instid0(SALU_CYCLE_1)
	s_mul_hi_u32 s26, s44, 0xd2511f53
	s_mul_i32 s44, s44, 0xd2511f53
	s_xor_b64 s[26:27], s[26:27], s[22:23]
	s_mov_b32 s27, 0
	s_branch .LBB6_13
.Ltmp15:
.LBB6_12:                               ; %Flow13
                                        ;   in Loop: Header=BB6_13 Depth=2
	.loc	6 0 0 is_stmt 0                 ; int.jl:0:0
	s_delay_alu instid0(VALU_DEP_2)
	.loc	7 305 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:305:0
	s_and_not1_b32 vcc_lo, exec_lo, s46
	s_cbranch_vccz .LBB6_15
.LBB6_13:                               ; %L343
                                        ;   Parent Loop BB6_10 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	.loc	7 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:0:0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
.Ltmp16:
	.loc	6 535 0 is_stmt 1               ; int.jl:535:0
	s_lshl_b32 s17, s27, 24
.Ltmp17:
	.loc	6 378 0                         ; int.jl:378:0
	s_or_b64 s[46:47], s[16:17], s[6:7]
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
.Ltmp18:
	.loc	1 936 0                         ; boot.jl:936:0
	s_xor_b32 s17, s47, s4
.Ltmp19:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s45, s17, 0xd2511f53
	s_mul_i32 s17, s17, 0xd2511f53
.Ltmp20:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s19, s45
.Ltmp21:
	.loc	6 379 0 is_stmt 0               ; int.jl:379:0
	s_xor_b32 s17, s26, s17
.Ltmp22:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s45, s18
.Ltmp23:
	.loc	6 88 0 is_stmt 1                ; int.jl:88:0
	s_mul_i32 s46, s17, 0xcd9e8d57
.Ltmp24:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_i32 s47, s45, 0xcd9e8d57
	s_mul_hi_u32 s45, s45, 0xcd9e8d57
.Ltmp25:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s17, s17, 0xcd9e8d57
.Ltmp26:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s45, s20, s45
.Ltmp27:
	.loc	6 379 0 is_stmt 0               ; int.jl:379:0
	s_xor_b32 s17, s17, s28
.Ltmp28:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s45, s43
.Ltmp29:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s17, s47
.Ltmp30:
	.loc	6 88 0 is_stmt 1                ; int.jl:88:0
	s_mul_hi_u32 s48, s45, 0xd2511f53
.Ltmp31:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_i32 s47, s17, 0xd2511f53
.Ltmp32:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s48, s29, s48
.Ltmp33:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s17, s17, 0xd2511f53
.Ltmp34:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s48, s48, s44
.Ltmp35:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_i32 s45, s45, 0xd2511f53
.Ltmp36:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s17, s31
.Ltmp37:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s49, s48, 0xcd9e8d57
.Ltmp38:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s17, s45
	s_xor_b32 s45, s30, s49
.Ltmp39:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s49, s17, 0xcd9e8d57
.Ltmp40:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s45, s46
.Ltmp41:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_i32 s48, s48, 0xcd9e8d57
.Ltmp42:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_i32 s46, s45, 0xd2511f53
	s_mul_hi_u32 s45, s45, 0xd2511f53
.Ltmp43:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s49, s49, s33
	s_xor_b32 s45, s34, s45
	s_xor_b32 s48, s49, s48
	s_xor_b32 s45, s45, s47
.Ltmp44:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s47, s48, 0xd2511f53
.Ltmp45:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_i32 s49, s45, 0xcd9e8d57
.Ltmp46:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s47, s47, s36
.Ltmp47:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s45, s45, 0xcd9e8d57
.Ltmp48:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s46, s47, s46
.Ltmp49:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_i32 s17, s17, 0xcd9e8d57
.Ltmp50:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_hi_u32 s46, s46, 0xcd9e8d57
.Ltmp51:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s45, s35, s45
.Ltmp52:
	.loc	6 379 0 is_stmt 0               ; int.jl:379:0
	s_xor_b32 s46, s46, s37
.Ltmp53:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s45, s17
.Ltmp54:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s46, s49
.Ltmp55:
	.loc	6 88 0 is_stmt 1                ; int.jl:88:0
	s_mul_i32 s46, s17, 0xd2511f53
.Ltmp56:
	.loc	6 88 0 is_stmt 0                ; int.jl:88:0
	s_mul_hi_u32 s45, s45, 0xd2511f53
.Ltmp57:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_hi_u32 s17, s17, 0xd2511f53
.Ltmp58:
	.loc	6 379 0 is_stmt 1               ; int.jl:379:0
	s_xor_b32 s45, s45, s5
.Ltmp59:
	.loc	6 88 0                          ; int.jl:88:0
	s_mul_i32 s48, s48, 0xd2511f53
.Ltmp60:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s38, s17
.Ltmp61:
	.loc	6 379 0 is_stmt 0               ; int.jl:379:0
	s_xor_b32 s45, s45, s46
.Ltmp62:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s17, s17, s48
.Ltmp63:
	.loc	6 88 0 is_stmt 1                ; int.jl:88:0
	s_mul_hi_u32 s45, s45, 0xcd9e8d57
.Ltmp64:
	.loc	6 550 0                         ; int.jl:550:0
	s_mul_i32 s17, s17, 0xcd9e8d57
.Ltmp65:
	.loc	6 379 0                         ; int.jl:379:0
	s_xor_b32 s45, s39, s45
	s_mov_b32 s46, -1
	s_xor_b32 s45, s45, s17
	s_mov_b32 s17, -1
.Ltmp66:
	.loc	6 521 0                         ; int.jl:521:0
	s_cmp_gt_u32 s42, s45
.Ltmp67:
	.loc	7 305 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:305:0
	s_cbranch_scc0 .LBB6_12
; %bb.14:                               ; %L508
                                        ;   in Loop: Header=BB6_13 Depth=2
.Ltmp68:
	.loc	5 637 0                         ; promotion.jl:637:0
	v_and_b32_e64 v1, 0xff, s27
	s_mov_b32 s17, 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)
.Ltmp69:
	.loc	6 87 0                          ; int.jl:87:0
	v_add_nc_u16 v2, v1, 1
.Ltmp70:
	.loc	5 637 0                         ; promotion.jl:637:0
	v_cmp_eq_u16_e64 s46, 0xff, v1
.Ltmp71:
	.loc	6 87 0                          ; int.jl:87:0
	v_readfirstlane_b32 s27, v2
	s_branch .LBB6_12
.Ltmp72:
.LBB6_15:                               ; %loop.exit.guard9
                                        ;   in Loop: Header=BB6_10 Depth=1
	.loc	6 0 0 is_stmt 0                 ; int.jl:0:0
	s_mov_b32 s26, -1
	s_and_b32 vcc_lo, exec_lo, s17
	s_mov_b32 s27, s17
	s_cbranch_vccz .LBB6_9
; %bb.16:                               ; %L506
                                        ;   in Loop: Header=BB6_10 Depth=1
.Ltmp73:
	.loc	6 304 0 is_stmt 1               ; int.jl:304:0
	s_mul_hi_u32 s9, s45, s9
.Ltmp74:
	.loc	1 881 0                         ; boot.jl:881:0
	s_mov_b32 s27, 0
.Ltmp75:
	.loc	6 304 0                         ; int.jl:304:0
	s_mul_i32 s9, s9, s24
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(NEXT) | instid1(SALU_CYCLE_1)
	s_sub_i32 s9, s45, s9
	s_sub_i32 s17, s9, s24
	s_cmp_ge_u32 s9, s24
	s_cselect_b32 s9, s17, s9
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	s_sub_i32 s17, s9, s24
	s_cmp_ge_u32 s9, s24
	s_cselect_b32 s26, s17, s9
	s_mov_b32 s17, -1
.Ltmp76:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_lshl_b64 s[42:43], s[26:27], 2
	s_add_u32 s42, s0, s42
	s_addc_u32 s43, s1, s43
	s_lshl_b64 s[44:45], s[24:25], 2
	global_load_b32 v1, v0, s[42:43]
	s_add_u32 s44, s40, s44
	s_addc_u32 s45, s41, s45
.Ltmp77:
	.file	8 "." "range.jl"
	.loc	8 921 0                         ; range.jl:921:0
	s_add_u32 s46, s24, -1
.Ltmp78:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b32 v2, v0, s[44:45]
.Ltmp79:
	.loc	8 921 0                         ; range.jl:921:0
	s_addc_u32 s47, s25, -1
.Ltmp80:
	.loc	5 637 0                         ; promotion.jl:637:0
	s_cmp_eq_u64 s[24:25], s[10:11]
	s_mov_b64 s[24:25], s[46:47]
	s_cselect_b32 s26, -1, 0
.Ltmp81:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(1)
	global_store_b32 v0, v1, s[44:45]
	s_waitcnt vmcnt(0)
	global_store_b32 v0, v2, s[42:43]
.Ltmp82:
	.loc	3 240 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:240:0
	s_branch .LBB6_9
.LBB6_17:                               ; %loop.exit.guard
	.loc	3 0 0 is_stmt 0                 ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:0:0
	s_mov_b32 s0, -1
	s_and_b32 vcc_lo, exec_lo, s27
	s_mov_b32 s1, 0
	s_cbranch_vccnz .LBB6_19
; %bb.18:                               ; %loop.exit.guard8
	s_xor_b32 s1, s17, -1
	s_mov_b32 s0, 0
	s_and_b32 vcc_lo, exec_lo, s1
	s_mov_b32 s1, 0
	s_cbranch_vccnz .LBB6_24
.LBB6_19:                               ; %Flow
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccnz .LBB6_25
.LBB6_20:                               ; %Flow11
	s_and_not1_b32 vcc_lo, exec_lo, s1
	s_cbranch_vccnz .LBB6_22
.LBB6_21:                               ; %UnifiedUnreachableBlock
	; divergent unreachable
.LBB6_22:                               ; %UnifiedReturnBlock
	s_nop 0
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
.LBB6_23:
                                        ; implicit-def: $sgpr10_sgpr11
	.loc	3 230 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:230:0
	s_cbranch_execz .LBB6_6
	s_branch .LBB6_5
.LBB6_24:                               ; %L510
.Ltmp83:
	.loc	7 306 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:306:0
	s_getpc_b64 s[4:5]
	s_add_u32 s4, s4, julia_ArgumentError_17125@rel32@lo+4
	s_addc_u32 s5, s5, julia_ArgumentError_17125@rel32@hi+12
	s_delay_alu instid0(SALU_CYCLE_1)
	s_swappc_b64 s[30:31], s[4:5]
.Ltmp84:
	.loc	6 550 0                         ; int.jl:550:0
	s_lshl_b32 s1, s13, 16
.Ltmp85:
	.loc	6 550 0 is_stmt 0               ; int.jl:550:0
	s_add_i32 s6, s14, 1
	s_mov_b32 s4, 0
.Ltmp86:
	.loc	6 535 0 is_stmt 1               ; int.jl:535:0
	s_add_i32 s5, s1, 0x10000
.Ltmp87:
	.loc	1 935 0                         ; boot.jl:935:0
	s_and_b32 s7, s6, 0xffff
.Ltmp88:
	.loc	6 535 0                         ; int.jl:535:0
	s_mov_b32 s6, s4
.Ltmp89:
	.loc	6 535 0 is_stmt 0               ; int.jl:535:0
	s_lshl_b32 s1, s15, 16
.Ltmp90:
	.loc	6 378 0 is_stmt 1               ; int.jl:378:0
	s_or_b64 s[4:5], s[6:7], s[4:5]
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
.Ltmp91:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v2, 0 :: v_dual_mov_b32 v1, s5
.Ltmp92:
	.loc	6 378 0                         ; int.jl:378:0
	s_add_i32 s1, s1, 0x10001
.Ltmp93:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v5, s3 :: v_dual_mov_b32 v4, s2
.Ltmp94:
	.loc	4 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v0, s1 :: v_dual_mov_b32 v3, v2
	s_waitcnt_vscnt null, 0x0
	flat_atomic_cmpswap_b64 v[4:5], v[0:3]
	s_waitcnt lgkmcnt(0)
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.Ltmp95:
	.file	9 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/gcn/execution_control.jl"
	.loc	9 6 0 is_stmt 1                 ; /home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/gcn/execution_control.jl:6:0
	s_endpgm
	s_mov_b32 s1, -1
	s_and_b32 vcc_lo, exec_lo, s0
	s_cbranch_vccz .LBB6_20
.Ltmp96:
.LBB6_25:                               ; %L515
	.loc	7 300 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/rng/semantic.jl:300:0
	s_getpc_b64 s[0:1]
	s_add_u32 s0, s0, julia_ArgumentError_17125@rel32@lo+4
	s_addc_u32 s1, s1, julia_ArgumentError_17125@rel32@hi+12
	s_delay_alu instid0(SALU_CYCLE_1)
	s_swappc_b64 s[30:31], s[0:1]
.Ltmp97:
	.loc	6 550 0                         ; int.jl:550:0
	s_lshl_b32 s0, s13, 16
.Ltmp98:
	.loc	6 550 0 is_stmt 0               ; int.jl:550:0
	s_add_i32 s14, s14, 1
.Ltmp99:
	.loc	6 535 0 is_stmt 1               ; int.jl:535:0
	s_add_i32 s1, s0, 0x10000
	s_mov_b32 s0, 0
.Ltmp100:
	.loc	1 935 0                         ; boot.jl:935:0
	s_and_b32 s5, s14, 0xffff
.Ltmp101:
	.loc	6 535 0                         ; int.jl:535:0
	s_mov_b32 s4, s0
.Ltmp102:
	.loc	6 535 0 is_stmt 0               ; int.jl:535:0
	s_lshl_b32 s6, s15, 16
.Ltmp103:
	.loc	6 378 0 is_stmt 1               ; int.jl:378:0
	s_or_b64 s[0:1], s[4:5], s[0:1]
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
.Ltmp104:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v2, 0 :: v_dual_mov_b32 v1, s1
.Ltmp105:
	.loc	6 378 0                         ; int.jl:378:0
	s_add_i32 s6, s6, 0x10001
.Ltmp106:
	.loc	4 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v5, s3 :: v_dual_mov_b32 v4, s2
.Ltmp107:
	.loc	4 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_dual_mov_b32 v0, s6 :: v_dual_mov_b32 v3, v2
	s_waitcnt_vscnt null, 0x0
	flat_atomic_cmpswap_b64 v[4:5], v[0:3]
	s_waitcnt lgkmcnt(0)
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.Ltmp108:
	.loc	9 6 0 is_stmt 1                 ; /home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/gcn/execution_control.jl:6:0
	s_endpgm
	s_branch .LBB6_21
.Ltmp109:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 100
		.amdhsa_user_sgpr_count 13
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 1
		.amdhsa_enable_private_segment 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 1
		.amdhsa_system_sgpr_workgroup_id_z 1
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 6
		.amdhsa_next_free_sgpr 50
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 0
		.amdhsa_shared_vgpr_count 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel
	.text
.Lfunc_end6:
	.size	_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_, .Lfunc_end6-_Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_
	.cfi_endproc
	.file	10 "." "/home/praneeth/.julia/packages/KernelAbstractions/scVtc/src/macros.jl"
	.file	11 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/gcn/array.jl"
	.file	12 "." "/home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/pointer.jl"
	.file	13 "." "operators.jl"
	.file	14 "." "number.jl"
	.file	15 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/runtime.jl"
	.file	16 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/exceptions.jl"
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1600
; NumSgprs: 52
; NumVgprs: 6
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 6
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 52
; NumVGPRsForWavesPerEU: 6
; Occupancy: 16
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 13
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 1
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	0                               ; DW_CHILDREN_no
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	2                               ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	4                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	1                               ; DW_CHILDREN_yes
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	5                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	6                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	7                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	8                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	9                               ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	10                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	11                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	12                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	19                              ; DW_FORM_ref4
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	13                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	14                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	15                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	16                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	1                               ; DW_CHILDREN_yes
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	17                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	17                              ; DW_AT_low_pc
	.byte	1                               ; DW_FORM_addr
	.byte	18                              ; DW_AT_high_pc
	.byte	6                               ; DW_FORM_data4
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	18                              ; Abbreviation Code
	.byte	29                              ; DW_TAG_inlined_subroutine
	.byte	0                               ; DW_CHILDREN_no
	.byte	49                              ; DW_AT_abstract_origin
	.byte	16                              ; DW_FORM_ref_addr
	.byte	85                              ; DW_AT_ranges
	.byte	23                              ; DW_FORM_sec_offset
	.byte	88                              ; DW_AT_call_file
	.byte	11                              ; DW_FORM_data1
	.byte	89                              ; DW_AT_call_line
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	19                              ; Abbreviation Code
	.byte	17                              ; DW_TAG_compile_unit
	.byte	1                               ; DW_CHILDREN_yes
	.byte	37                              ; DW_AT_producer
	.byte	14                              ; DW_FORM_strp
	.byte	19                              ; DW_AT_language
	.byte	5                               ; DW_FORM_data2
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	16                              ; DW_AT_stmt_list
	.byte	23                              ; DW_FORM_sec_offset
	.byte	27                              ; DW_AT_comp_dir
	.byte	14                              ; DW_FORM_strp
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0x1f DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	31                              ; DW_AT_language
	.long	.Linfo_string0                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string1                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin0                   ; DW_AT_low_pc
	.long	.Lfunc_end0-.Lfunc_begin0       ; DW_AT_high_pc
.Ldebug_info_end0:
.Lcu_begin1:
	.long	.Ldebug_info_end1-.Ldebug_info_start1 ; Length of Unit
.Ldebug_info_start1:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	2                               ; Abbrev [2] 0xb:0xb25 DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	31                              ; DW_AT_language
	.long	.Linfo_string0                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string1                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin6                   ; DW_AT_low_pc
	.long	.Lfunc_end6-.Lfunc_begin6       ; DW_AT_high_pc
	.byte	3                               ; Abbrev [3] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x36:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x3c:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x42:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x48:0x6 DW_TAG_subprogram
	.long	.Linfo_string4                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x4e:0x6 DW_TAG_subprogram
	.long	.Linfo_string5                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x54:0x6 DW_TAG_subprogram
	.long	.Linfo_string6                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x5a:0x6 DW_TAG_subprogram
	.long	.Linfo_string7                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x60:0x6 DW_TAG_subprogram
	.long	.Linfo_string8                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x66:0x6 DW_TAG_subprogram
	.long	.Linfo_string9                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x6c:0x6 DW_TAG_subprogram
	.long	.Linfo_string10                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x72:0x6 DW_TAG_subprogram
	.long	.Linfo_string11                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x78:0x6 DW_TAG_subprogram
	.long	.Linfo_string12                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x7e:0x6 DW_TAG_subprogram
	.long	.Linfo_string13                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x84:0x6 DW_TAG_subprogram
	.long	.Linfo_string14                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x8a:0x6 DW_TAG_subprogram
	.long	.Linfo_string15                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x90:0x6 DW_TAG_subprogram
	.long	.Linfo_string16                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x96:0x6 DW_TAG_subprogram
	.long	.Linfo_string17                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x9c:0x6 DW_TAG_subprogram
	.long	.Linfo_string14                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xa2:0x6 DW_TAG_subprogram
	.long	.Linfo_string18                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xa8:0x6 DW_TAG_subprogram
	.long	.Linfo_string19                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xae:0x6 DW_TAG_subprogram
	.long	.Linfo_string20                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xb4:0x6 DW_TAG_subprogram
	.long	.Linfo_string21                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xba:0x6 DW_TAG_subprogram
	.long	.Linfo_string22                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xc0:0x6 DW_TAG_subprogram
	.long	.Linfo_string23                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xc6:0x6 DW_TAG_subprogram
	.long	.Linfo_string24                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xcc:0x6 DW_TAG_subprogram
	.long	.Linfo_string25                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xd2:0x6 DW_TAG_subprogram
	.long	.Linfo_string26                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xd8:0x6 DW_TAG_subprogram
	.long	.Linfo_string27                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xde:0x6 DW_TAG_subprogram
	.long	.Linfo_string28                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xe4:0x6 DW_TAG_subprogram
	.long	.Linfo_string29                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xea:0x6 DW_TAG_subprogram
	.long	.Linfo_string30                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xf0:0x6 DW_TAG_subprogram
	.long	.Linfo_string31                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xf6:0x6 DW_TAG_subprogram
	.long	.Linfo_string32                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0xfc:0x6 DW_TAG_subprogram
	.long	.Linfo_string33                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x102:0x6 DW_TAG_subprogram
	.long	.Linfo_string34                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x108:0x6 DW_TAG_subprogram
	.long	.Linfo_string35                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x10e:0x6 DW_TAG_subprogram
	.long	.Linfo_string36                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x114:0x6 DW_TAG_subprogram
	.long	.Linfo_string37                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x11a:0x6 DW_TAG_subprogram
	.long	.Linfo_string38                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x120:0x6 DW_TAG_subprogram
	.long	.Linfo_string39                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x126:0x6 DW_TAG_subprogram
	.long	.Linfo_string40                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x12c:0x6 DW_TAG_subprogram
	.long	.Linfo_string41                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	4                               ; Abbrev [4] 0x132:0x9fd DW_TAG_subprogram
	.quad	.Lfunc_begin6                   ; DW_AT_low_pc
	.long	.Lfunc_end6-.Lfunc_begin6       ; DW_AT_high_pc
	.long	.Linfo_string48                 ; DW_AT_name
	.byte	5                               ; Abbrev [5] 0x143:0x9eb DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp2                          ; DW_AT_low_pc
	.long	.Ltmp109-.Ltmp2                 ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x156:0x9d7 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp2                          ; DW_AT_low_pc
	.long	.Ltmp109-.Ltmp2                 ; DW_AT_high_pc
	.byte	10                              ; DW_AT_call_file
	.short	332                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x16a:0x63 DW_TAG_inlined_subroutine
	.long	78                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	231                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x17d:0x4f DW_TAG_inlined_subroutine
	.long	72                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	11                              ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x190:0x3b DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	12                              ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x1a3:0x27 DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x1b6:0x13 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x1cd:0x28 DW_TAG_inlined_subroutine
	.long	90                              ; DW_AT_abstract_origin
	.quad	.Ltmp4                          ; DW_AT_low_pc
	.long	.Ltmp5-.Ltmp4                   ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	232                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x1e0:0x14 DW_TAG_inlined_subroutine
	.long	84                              ; DW_AT_abstract_origin
	.quad	.Ltmp4                          ; DW_AT_low_pc
	.long	.Ltmp5-.Ltmp4                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	921                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x1f5:0x8f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	233                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x208:0x7b DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	22                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x21b:0x67 DW_TAG_inlined_subroutine
	.long	114                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	24                              ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x22e:0x53 DW_TAG_inlined_subroutine
	.long	114                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	391                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x242:0x3e DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	336                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x256:0x29 DW_TAG_inlined_subroutine
	.long	102                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	355                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x26a:0x14 DW_TAG_inlined_subroutine
	.long	96                              ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	382                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x284:0x52 DW_TAG_inlined_subroutine
	.long	90                              ; DW_AT_abstract_origin
	.quad	.Ltmp8                          ; DW_AT_low_pc
	.long	.Ltmp9-.Ltmp8                   ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	233                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x297:0x3e DW_TAG_inlined_subroutine
	.long	144                             ; DW_AT_abstract_origin
	.quad	.Ltmp8                          ; DW_AT_low_pc
	.long	.Ltmp9-.Ltmp8                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	917                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x2ab:0x29 DW_TAG_inlined_subroutine
	.long	138                             ; DW_AT_abstract_origin
	.quad	.Ltmp8                          ; DW_AT_low_pc
	.long	.Ltmp9-.Ltmp8                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	685                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x2bf:0x14 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp8                          ; DW_AT_low_pc
	.long	.Ltmp9-.Ltmp8                   ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.short	425                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x2d6:0x770 DW_TAG_inlined_subroutine
	.long	150                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	3                               ; DW_AT_call_file
	.byte	237                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x2e1:0x53 DW_TAG_inlined_subroutine
	.long	138                             ; DW_AT_abstract_origin
	.quad	.Ltmp11                         ; DW_AT_low_pc
	.long	.Ltmp12-.Ltmp11                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	300                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x2f5:0x3e DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp11                         ; DW_AT_low_pc
	.long	.Ltmp12-.Ltmp11                 ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.short	425                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x309:0x29 DW_TAG_inlined_subroutine
	.long	156                             ; DW_AT_abstract_origin
	.quad	.Ltmp11                         ; DW_AT_low_pc
	.long	.Ltmp12-.Ltmp11                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	525                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x31d:0x14 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp11                         ; DW_AT_low_pc
	.long	.Ltmp12-.Ltmp11                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	488                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	10                              ; Abbrev [10] 0x334:0x19 DW_TAG_inlined_subroutine
	.long	168                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.short	301                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x340:0xc DW_TAG_inlined_subroutine
	.long	162                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	6                               ; DW_AT_call_file
	.short	297                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x34d:0x14 DW_TAG_inlined_subroutine
	.long	174                             ; DW_AT_abstract_origin
	.quad	.Ltmp13                         ; DW_AT_low_pc
	.long	.Ltmp14-.Ltmp13                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	301                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x361:0x3ac DW_TAG_inlined_subroutine
	.long	198                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp16                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	304                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x375:0x397 DW_TAG_inlined_subroutine
	.long	198                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp16                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	271                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x389:0x382 DW_TAG_inlined_subroutine
	.long	192                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp16                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	272                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x39d:0x50 DW_TAG_inlined_subroutine
	.long	186                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp18-.Ltmp16                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	265                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x3b1:0x28 DW_TAG_inlined_subroutine
	.long	180                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp17-.Ltmp16                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	251                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x3c4:0x14 DW_TAG_inlined_subroutine
	.long	180                             ; DW_AT_abstract_origin
	.quad	.Ltmp16                         ; DW_AT_low_pc
	.long	.Ltmp17-.Ltmp16                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x3d9:0x13 DW_TAG_inlined_subroutine
	.long	204                             ; DW_AT_abstract_origin
	.quad	.Ltmp17                         ; DW_AT_low_pc
	.long	.Ltmp18-.Ltmp17                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	251                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	6                               ; Abbrev [6] 0x3ed:0x31d DW_TAG_inlined_subroutine
	.long	246                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp18                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	266                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x401:0x308 DW_TAG_inlined_subroutine
	.long	246                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp18                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	186                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x414:0x91 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	162                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x41f:0x7a DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp20-.Ltmp18                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x432:0x52 DW_TAG_inlined_subroutine
	.long	228                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp19-.Ltmp18                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x446:0x3d DW_TAG_inlined_subroutine
	.long	222                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp19-.Ltmp18                 ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.short	946                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x45a:0x28 DW_TAG_inlined_subroutine
	.long	216                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp19-.Ltmp18                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.byte	7                               ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x46d:0x14 DW_TAG_inlined_subroutine
	.long	210                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp19-.Ltmp18                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	962                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x484:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp19                         ; DW_AT_low_pc
	.long	.Ltmp20-.Ltmp19                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x499:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x4a5:0x3f DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	164                             ; DW_AT_call_line
	.byte	12                              ; Abbrev [12] 0x4b0:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x4bb:0x28 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp24                         ; DW_AT_low_pc
	.long	.Ltmp25-.Ltmp24                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x4ce:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp24                         ; DW_AT_low_pc
	.long	.Ltmp25-.Ltmp24                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x4e4:0x47 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	166                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x4ef:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x4fa:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x507:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x512:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges11                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x51d:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges12                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x52b:0x47 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges13                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	168                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x536:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges14                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x541:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges15                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x54e:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges16                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x559:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges17                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x564:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges18                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x572:0x5f DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges19                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	170                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x57d:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges20                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x588:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges21                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x595:0x28 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp42                         ; DW_AT_low_pc
	.long	.Ltmp43-.Ltmp42                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x5a8:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp42                         ; DW_AT_low_pc
	.long	.Ltmp43-.Ltmp42                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x5bd:0x13 DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.quad	.Ltmp43                         ; DW_AT_low_pc
	.long	.Ltmp44-.Ltmp43                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x5d1:0x47 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges22                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	172                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x5dc:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges23                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x5e7:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges24                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x5f4:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges25                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x5ff:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges26                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x60c:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges27                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x618:0x57 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges28                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	174                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x623:0x28 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp50                         ; DW_AT_low_pc
	.long	.Ltmp51-.Ltmp50                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x636:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp50                         ; DW_AT_low_pc
	.long	.Ltmp51-.Ltmp50                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x64b:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges29                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x656:0x18 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges30                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x661:0xc DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges31                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x66f:0x52 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges32                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	176                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x67a:0x28 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp56                         ; DW_AT_low_pc
	.long	.Ltmp57-.Ltmp56                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	145                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x68d:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp56                         ; DW_AT_low_pc
	.long	.Ltmp57-.Ltmp56                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	12                              ; Abbrev [12] 0x6a2:0xb DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges33                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x6ad:0x13 DW_TAG_inlined_subroutine
	.long	162                             ; DW_AT_abstract_origin
	.quad	.Ltmp64                         ; DW_AT_low_pc
	.long	.Ltmp65-.Ltmp64                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	150                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0x6c1:0x47 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges34                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.byte	178                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x6cc:0x28 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp63                         ; DW_AT_low_pc
	.long	.Ltmp64-.Ltmp63                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	146                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x6df:0x14 DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp63                         ; DW_AT_low_pc
	.long	.Ltmp64-.Ltmp63                 ; DW_AT_high_pc
	.byte	14                              ; DW_AT_call_file
	.short	277                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x6f4:0x13 DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.quad	.Ltmp65                         ; DW_AT_low_pc
	.long	.Ltmp66-.Ltmp65                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.byte	151                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	6                               ; Abbrev [6] 0x70d:0x29 DW_TAG_inlined_subroutine
	.long	270                             ; DW_AT_abstract_origin
	.quad	.Ltmp66                         ; DW_AT_low_pc
	.long	.Ltmp67-.Ltmp66                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	305                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x721:0x14 DW_TAG_inlined_subroutine
	.long	264                             ; DW_AT_abstract_origin
	.quad	.Ltmp66                         ; DW_AT_low_pc
	.long	.Ltmp67-.Ltmp66                 ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.short	472                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	11                              ; Abbrev [11] 0x736:0xc DW_TAG_inlined_subroutine
	.long	84                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges35                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.short	306                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x742:0xc DW_TAG_inlined_subroutine
	.long	96                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges36                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.short	308                             ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x74e:0x19 DW_TAG_inlined_subroutine
	.long	168                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges37                ; DW_AT_ranges
	.byte	7                               ; DW_AT_call_file
	.short	305                             ; DW_AT_call_line
	.byte	11                              ; Abbrev [11] 0x75a:0xc DW_TAG_inlined_subroutine
	.long	162                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges38                ; DW_AT_ranges
	.byte	6                               ; DW_AT_call_file
	.short	297                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	13                              ; Abbrev [13] 0x767:0x16f DW_TAG_inlined_subroutine
	.long	.debug_info+2954                ; DW_AT_abstract_origin
	.quad	.Ltmp84                         ; DW_AT_low_pc
	.long	.Ltmp96-.Ltmp84                 ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	306                             ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x77b:0x11f DW_TAG_inlined_subroutine
	.long	.debug_info+2948                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges39                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	80                              ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x786:0xdd DW_TAG_inlined_subroutine
	.long	.debug_info+2942                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges40                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	60                              ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0x791:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2936                ; DW_AT_abstract_origin
	.quad	.Ltmp84                         ; DW_AT_low_pc
	.long	.Ltmp85-.Ltmp84                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	36                              ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0x7a4:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2936                ; DW_AT_abstract_origin
	.quad	.Ltmp85                         ; DW_AT_low_pc
	.long	.Ltmp86-.Ltmp85                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	16                              ; Abbrev [16] 0x7b7:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp86                         ; DW_AT_low_pc
	.long	.Ltmp87-.Ltmp86                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	36                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x7ca:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp86                         ; DW_AT_low_pc
	.long	.Ltmp87-.Ltmp86                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x7df:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2972                ; DW_AT_abstract_origin
	.quad	.Ltmp87                         ; DW_AT_low_pc
	.long	.Ltmp88-.Ltmp87                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x7f2:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2966                ; DW_AT_abstract_origin
	.quad	.Ltmp87                         ; DW_AT_low_pc
	.long	.Ltmp88-.Ltmp87                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	962                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x807:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp88                         ; DW_AT_low_pc
	.long	.Ltmp89-.Ltmp88                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x81a:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp88                         ; DW_AT_low_pc
	.long	.Ltmp89-.Ltmp88                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x82f:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp89                         ; DW_AT_low_pc
	.long	.Ltmp90-.Ltmp89                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	38                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x842:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp89                         ; DW_AT_low_pc
	.long	.Ltmp90-.Ltmp89                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	18                              ; Abbrev [18] 0x857:0xb DW_TAG_inlined_subroutine
	.long	.debug_info+2978                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges41                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	39                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	14                              ; Abbrev [14] 0x863:0x23 DW_TAG_inlined_subroutine
	.long	.debug_info+2996                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges42                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	63                              ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x86e:0x17 DW_TAG_inlined_subroutine
	.long	.debug_info+2990                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges43                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	10                              ; DW_AT_call_line
	.byte	18                              ; Abbrev [18] 0x879:0xb DW_TAG_inlined_subroutine
	.long	.debug_info+2984                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges44                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	10                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	15                              ; Abbrev [15] 0x886:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+3014                ; DW_AT_abstract_origin
	.quad	.Ltmp95                         ; DW_AT_low_pc
	.long	.Ltmp96-.Ltmp95                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	64                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x89a:0x3b DW_TAG_inlined_subroutine
	.long	.debug_info+3008                ; DW_AT_abstract_origin
	.quad	.Ltmp93                         ; DW_AT_low_pc
	.long	.Ltmp94-.Ltmp93                 ; DW_AT_high_pc
	.byte	15                              ; DW_AT_call_file
	.byte	79                              ; DW_AT_call_line
	.byte	16                              ; Abbrev [16] 0x8ad:0x27 DW_TAG_inlined_subroutine
	.long	.debug_info+3002                ; DW_AT_abstract_origin
	.quad	.Ltmp93                         ; DW_AT_low_pc
	.long	.Ltmp94-.Ltmp93                 ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0x8c0:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2984                ; DW_AT_abstract_origin
	.quad	.Ltmp93                         ; DW_AT_low_pc
	.long	.Ltmp94-.Ltmp93                 ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	13                              ; Abbrev [13] 0x8d6:0x16f DW_TAG_inlined_subroutine
	.long	.debug_info+2954                ; DW_AT_abstract_origin
	.quad	.Ltmp97                         ; DW_AT_low_pc
	.long	.Ltmp109-.Ltmp97                ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	300                             ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x8ea:0x11f DW_TAG_inlined_subroutine
	.long	.debug_info+2948                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges45                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	80                              ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x8f5:0xdd DW_TAG_inlined_subroutine
	.long	.debug_info+2942                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges46                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	60                              ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0x900:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2936                ; DW_AT_abstract_origin
	.quad	.Ltmp97                         ; DW_AT_low_pc
	.long	.Ltmp98-.Ltmp97                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	36                              ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0x913:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2936                ; DW_AT_abstract_origin
	.quad	.Ltmp98                         ; DW_AT_low_pc
	.long	.Ltmp99-.Ltmp98                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	16                              ; Abbrev [16] 0x926:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp99                         ; DW_AT_low_pc
	.long	.Ltmp100-.Ltmp99                ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	36                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x939:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp99                         ; DW_AT_low_pc
	.long	.Ltmp100-.Ltmp99                ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x94e:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2972                ; DW_AT_abstract_origin
	.quad	.Ltmp100                        ; DW_AT_low_pc
	.long	.Ltmp101-.Ltmp100               ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x961:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2966                ; DW_AT_abstract_origin
	.quad	.Ltmp100                        ; DW_AT_low_pc
	.long	.Ltmp101-.Ltmp100               ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	962                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x976:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp101                        ; DW_AT_low_pc
	.long	.Ltmp102-.Ltmp101               ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	37                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x989:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp101                        ; DW_AT_low_pc
	.long	.Ltmp102-.Ltmp101               ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0x99e:0x28 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp102                        ; DW_AT_low_pc
	.long	.Ltmp103-.Ltmp102               ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	38                              ; DW_AT_call_line
	.byte	17                              ; Abbrev [17] 0x9b1:0x14 DW_TAG_inlined_subroutine
	.long	.debug_info+2960                ; DW_AT_abstract_origin
	.quad	.Ltmp102                        ; DW_AT_low_pc
	.long	.Ltmp103-.Ltmp102               ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	542                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	18                              ; Abbrev [18] 0x9c6:0xb DW_TAG_inlined_subroutine
	.long	.debug_info+2978                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges47                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	39                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	14                              ; Abbrev [14] 0x9d2:0x23 DW_TAG_inlined_subroutine
	.long	.debug_info+2996                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges48                ; DW_AT_ranges
	.byte	16                              ; DW_AT_call_file
	.byte	63                              ; DW_AT_call_line
	.byte	14                              ; Abbrev [14] 0x9dd:0x17 DW_TAG_inlined_subroutine
	.long	.debug_info+2990                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges49                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	10                              ; DW_AT_call_line
	.byte	18                              ; Abbrev [18] 0x9e8:0xb DW_TAG_inlined_subroutine
	.long	.debug_info+2984                ; DW_AT_abstract_origin
	.long	.Ldebug_ranges50                ; DW_AT_ranges
	.byte	15                              ; DW_AT_call_file
	.byte	10                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	15                              ; Abbrev [15] 0x9f5:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+3014                ; DW_AT_abstract_origin
	.quad	.Ltmp108                        ; DW_AT_low_pc
	.long	.Ltmp109-.Ltmp108               ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	64                              ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	16                              ; Abbrev [16] 0xa09:0x3b DW_TAG_inlined_subroutine
	.long	.debug_info+3008                ; DW_AT_abstract_origin
	.quad	.Ltmp106                        ; DW_AT_low_pc
	.long	.Ltmp107-.Ltmp106               ; DW_AT_high_pc
	.byte	15                              ; DW_AT_call_file
	.byte	79                              ; DW_AT_call_line
	.byte	16                              ; Abbrev [16] 0xa1c:0x27 DW_TAG_inlined_subroutine
	.long	.debug_info+3002                ; DW_AT_abstract_origin
	.quad	.Ltmp106                        ; DW_AT_low_pc
	.long	.Ltmp107-.Ltmp106               ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	15                              ; Abbrev [15] 0xa2f:0x13 DW_TAG_inlined_subroutine
	.long	.debug_info+2984                ; DW_AT_abstract_origin
	.quad	.Ltmp106                        ; DW_AT_low_pc
	.long	.Ltmp107-.Ltmp106               ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0xa46:0x28 DW_TAG_inlined_subroutine
	.long	282                             ; DW_AT_abstract_origin
	.quad	.Ltmp74                         ; DW_AT_low_pc
	.long	.Ltmp75-.Ltmp74                 ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	237                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0xa59:0x14 DW_TAG_inlined_subroutine
	.long	276                             ; DW_AT_abstract_origin
	.quad	.Ltmp74                         ; DW_AT_low_pc
	.long	.Ltmp75-.Ltmp74                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.short	957                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0xa6e:0x3b DW_TAG_inlined_subroutine
	.long	300                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges51                ; DW_AT_ranges
	.byte	3                               ; DW_AT_call_file
	.byte	239                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa79:0x2f DW_TAG_inlined_subroutine
	.long	294                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges52                ; DW_AT_ranges
	.byte	11                              ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa84:0x23 DW_TAG_inlined_subroutine
	.long	288                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges53                ; DW_AT_ranges
	.byte	12                              ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa8f:0x17 DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges54                ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	12                              ; Abbrev [12] 0xa9a:0xb DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges55                ; DW_AT_ranges
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	9                               ; Abbrev [9] 0xaa9:0x20 DW_TAG_inlined_subroutine
	.long	90                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges56                ; DW_AT_ranges
	.byte	3                               ; DW_AT_call_file
	.byte	240                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0xab4:0x14 DW_TAG_inlined_subroutine
	.long	84                              ; DW_AT_abstract_origin
	.quad	.Ltmp80                         ; DW_AT_low_pc
	.long	.Ltmp81-.Ltmp80                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.short	921                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0xac9:0x63 DW_TAG_inlined_subroutine
	.long	78                              ; DW_AT_abstract_origin
	.quad	.Ltmp81                         ; DW_AT_low_pc
	.long	.Ltmp82-.Ltmp81                 ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.byte	239                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0xadc:0x4f DW_TAG_inlined_subroutine
	.long	72                              ; DW_AT_abstract_origin
	.quad	.Ltmp81                         ; DW_AT_low_pc
	.long	.Ltmp82-.Ltmp81                 ; DW_AT_high_pc
	.byte	11                              ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0xaef:0x3b DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.quad	.Ltmp81                         ; DW_AT_low_pc
	.long	.Ltmp82-.Ltmp81                 ; DW_AT_high_pc
	.byte	12                              ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0xb02:0x27 DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.quad	.Ltmp81                         ; DW_AT_low_pc
	.long	.Ltmp82-.Ltmp81                 ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0xb15:0x13 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.quad	.Ltmp81                         ; DW_AT_low_pc
	.long	.Ltmp82-.Ltmp81                 ; DW_AT_high_pc
	.byte	2                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end1:
.Lcu_begin2:
	.long	.Ldebug_info_end2-.Ldebug_info_start2 ; Length of Unit
.Ldebug_info_start2:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	19                              ; Abbrev [19] 0xb:0x68 DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	31                              ; DW_AT_language
	.long	.Linfo_string0                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string1                  ; DW_AT_comp_dir
	.byte	3                               ; Abbrev [3] 0x1e:0x6 DW_TAG_subprogram
	.long	.Linfo_string18                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x24:0x6 DW_TAG_subprogram
	.long	.Linfo_string42                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string43                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x30:0x6 DW_TAG_subprogram
	.long	.Linfo_string44                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x36:0x6 DW_TAG_subprogram
	.long	.Linfo_string21                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x3c:0x6 DW_TAG_subprogram
	.long	.Linfo_string26                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x42:0x6 DW_TAG_subprogram
	.long	.Linfo_string27                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x48:0x6 DW_TAG_subprogram
	.long	.Linfo_string25                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x4e:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x54:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x5a:0x6 DW_TAG_subprogram
	.long	.Linfo_string45                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x60:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x66:0x6 DW_TAG_subprogram
	.long	.Linfo_string46                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x6c:0x6 DW_TAG_subprogram
	.long	.Linfo_string47                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end2:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp10-.Lfunc_begin6
	.quad	.Ltmp74-.Lfunc_begin6
	.quad	.Ltmp75-.Lfunc_begin6
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp83-.Lfunc_begin6
	.quad	.Ltmp109-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp12-.Lfunc_begin6
	.quad	.Ltmp13-.Lfunc_begin6
	.quad	.Ltmp14-.Lfunc_begin6
	.quad	.Ltmp15-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp12-.Lfunc_begin6
	.quad	.Ltmp13-.Lfunc_begin6
	.quad	.Ltmp14-.Lfunc_begin6
	.quad	.Ltmp15-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp18-.Lfunc_begin6
	.quad	.Ltmp21-.Lfunc_begin6
	.quad	.Ltmp22-.Lfunc_begin6
	.quad	.Ltmp23-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp20-.Lfunc_begin6
	.quad	.Ltmp21-.Lfunc_begin6
	.quad	.Ltmp22-.Lfunc_begin6
	.quad	.Ltmp23-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp21-.Lfunc_begin6
	.quad	.Ltmp22-.Lfunc_begin6
	.quad	.Ltmp24-.Lfunc_begin6
	.quad	.Ltmp25-.Lfunc_begin6
	.quad	.Ltmp26-.Lfunc_begin6
	.quad	.Ltmp27-.Lfunc_begin6
	.quad	.Ltmp28-.Lfunc_begin6
	.quad	.Ltmp29-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp21-.Lfunc_begin6
	.quad	.Ltmp22-.Lfunc_begin6
	.quad	.Ltmp26-.Lfunc_begin6
	.quad	.Ltmp27-.Lfunc_begin6
	.quad	.Ltmp28-.Lfunc_begin6
	.quad	.Ltmp29-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp23-.Lfunc_begin6
	.quad	.Ltmp24-.Lfunc_begin6
	.quad	.Ltmp25-.Lfunc_begin6
	.quad	.Ltmp26-.Lfunc_begin6
	.quad	.Ltmp27-.Lfunc_begin6
	.quad	.Ltmp28-.Lfunc_begin6
	.quad	.Ltmp29-.Lfunc_begin6
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp32-.Lfunc_begin6
	.quad	.Ltmp33-.Lfunc_begin6
	.quad	.Ltmp34-.Lfunc_begin6
	.quad	.Ltmp36-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp23-.Lfunc_begin6
	.quad	.Ltmp24-.Lfunc_begin6
	.quad	.Ltmp25-.Lfunc_begin6
	.quad	.Ltmp26-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp23-.Lfunc_begin6
	.quad	.Ltmp24-.Lfunc_begin6
	.quad	.Ltmp25-.Lfunc_begin6
	.quad	.Ltmp26-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp27-.Lfunc_begin6
	.quad	.Ltmp28-.Lfunc_begin6
	.quad	.Ltmp29-.Lfunc_begin6
	.quad	.Ltmp30-.Lfunc_begin6
	.quad	.Ltmp32-.Lfunc_begin6
	.quad	.Ltmp33-.Lfunc_begin6
	.quad	.Ltmp34-.Lfunc_begin6
	.quad	.Ltmp35-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges11:
	.quad	.Ltmp30-.Lfunc_begin6
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp35-.Lfunc_begin6
	.quad	.Ltmp36-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges12:
	.quad	.Ltmp30-.Lfunc_begin6
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp35-.Lfunc_begin6
	.quad	.Ltmp36-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges13:
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp32-.Lfunc_begin6
	.quad	.Ltmp33-.Lfunc_begin6
	.quad	.Ltmp34-.Lfunc_begin6
	.quad	.Ltmp36-.Lfunc_begin6
	.quad	.Ltmp39-.Lfunc_begin6
	.quad	.Ltmp40-.Lfunc_begin6
	.quad	.Ltmp42-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges14:
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp32-.Lfunc_begin6
	.quad	.Ltmp33-.Lfunc_begin6
	.quad	.Ltmp34-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges15:
	.quad	.Ltmp31-.Lfunc_begin6
	.quad	.Ltmp32-.Lfunc_begin6
	.quad	.Ltmp33-.Lfunc_begin6
	.quad	.Ltmp34-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges16:
	.quad	.Ltmp36-.Lfunc_begin6
	.quad	.Ltmp37-.Lfunc_begin6
	.quad	.Ltmp38-.Lfunc_begin6
	.quad	.Ltmp39-.Lfunc_begin6
	.quad	.Ltmp40-.Lfunc_begin6
	.quad	.Ltmp41-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges17:
	.quad	.Ltmp37-.Lfunc_begin6
	.quad	.Ltmp38-.Lfunc_begin6
	.quad	.Ltmp41-.Lfunc_begin6
	.quad	.Ltmp42-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges18:
	.quad	.Ltmp37-.Lfunc_begin6
	.quad	.Ltmp38-.Lfunc_begin6
	.quad	.Ltmp41-.Lfunc_begin6
	.quad	.Ltmp42-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges19:
	.quad	.Ltmp39-.Lfunc_begin6
	.quad	.Ltmp40-.Lfunc_begin6
	.quad	.Ltmp42-.Lfunc_begin6
	.quad	.Ltmp44-.Lfunc_begin6
	.quad	.Ltmp49-.Lfunc_begin6
	.quad	.Ltmp50-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges20:
	.quad	.Ltmp39-.Lfunc_begin6
	.quad	.Ltmp40-.Lfunc_begin6
	.quad	.Ltmp49-.Lfunc_begin6
	.quad	.Ltmp50-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges21:
	.quad	.Ltmp39-.Lfunc_begin6
	.quad	.Ltmp40-.Lfunc_begin6
	.quad	.Ltmp49-.Lfunc_begin6
	.quad	.Ltmp50-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges22:
	.quad	.Ltmp44-.Lfunc_begin6
	.quad	.Ltmp49-.Lfunc_begin6
	.quad	.Ltmp51-.Lfunc_begin6
	.quad	.Ltmp52-.Lfunc_begin6
	.quad	.Ltmp53-.Lfunc_begin6
	.quad	.Ltmp54-.Lfunc_begin6
	.quad	.Ltmp59-.Lfunc_begin6
	.quad	.Ltmp60-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges23:
	.quad	.Ltmp44-.Lfunc_begin6
	.quad	.Ltmp45-.Lfunc_begin6
	.quad	.Ltmp59-.Lfunc_begin6
	.quad	.Ltmp60-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges24:
	.quad	.Ltmp44-.Lfunc_begin6
	.quad	.Ltmp45-.Lfunc_begin6
	.quad	.Ltmp59-.Lfunc_begin6
	.quad	.Ltmp60-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges25:
	.quad	.Ltmp45-.Lfunc_begin6
	.quad	.Ltmp46-.Lfunc_begin6
	.quad	.Ltmp47-.Lfunc_begin6
	.quad	.Ltmp48-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges26:
	.quad	.Ltmp45-.Lfunc_begin6
	.quad	.Ltmp46-.Lfunc_begin6
	.quad	.Ltmp47-.Lfunc_begin6
	.quad	.Ltmp48-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges27:
	.quad	.Ltmp46-.Lfunc_begin6
	.quad	.Ltmp47-.Lfunc_begin6
	.quad	.Ltmp48-.Lfunc_begin6
	.quad	.Ltmp49-.Lfunc_begin6
	.quad	.Ltmp51-.Lfunc_begin6
	.quad	.Ltmp52-.Lfunc_begin6
	.quad	.Ltmp53-.Lfunc_begin6
	.quad	.Ltmp54-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges28:
	.quad	.Ltmp50-.Lfunc_begin6
	.quad	.Ltmp51-.Lfunc_begin6
	.quad	.Ltmp52-.Lfunc_begin6
	.quad	.Ltmp53-.Lfunc_begin6
	.quad	.Ltmp54-.Lfunc_begin6
	.quad	.Ltmp56-.Lfunc_begin6
	.quad	.Ltmp57-.Lfunc_begin6
	.quad	.Ltmp58-.Lfunc_begin6
	.quad	.Ltmp60-.Lfunc_begin6
	.quad	.Ltmp61-.Lfunc_begin6
	.quad	.Ltmp62-.Lfunc_begin6
	.quad	.Ltmp63-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges29:
	.quad	.Ltmp52-.Lfunc_begin6
	.quad	.Ltmp53-.Lfunc_begin6
	.quad	.Ltmp54-.Lfunc_begin6
	.quad	.Ltmp55-.Lfunc_begin6
	.quad	.Ltmp60-.Lfunc_begin6
	.quad	.Ltmp61-.Lfunc_begin6
	.quad	.Ltmp62-.Lfunc_begin6
	.quad	.Ltmp63-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges30:
	.quad	.Ltmp55-.Lfunc_begin6
	.quad	.Ltmp56-.Lfunc_begin6
	.quad	.Ltmp57-.Lfunc_begin6
	.quad	.Ltmp58-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges31:
	.quad	.Ltmp55-.Lfunc_begin6
	.quad	.Ltmp56-.Lfunc_begin6
	.quad	.Ltmp57-.Lfunc_begin6
	.quad	.Ltmp58-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges32:
	.quad	.Ltmp56-.Lfunc_begin6
	.quad	.Ltmp57-.Lfunc_begin6
	.quad	.Ltmp58-.Lfunc_begin6
	.quad	.Ltmp59-.Lfunc_begin6
	.quad	.Ltmp61-.Lfunc_begin6
	.quad	.Ltmp62-.Lfunc_begin6
	.quad	.Ltmp64-.Lfunc_begin6
	.quad	.Ltmp65-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges33:
	.quad	.Ltmp58-.Lfunc_begin6
	.quad	.Ltmp59-.Lfunc_begin6
	.quad	.Ltmp61-.Lfunc_begin6
	.quad	.Ltmp62-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges34:
	.quad	.Ltmp63-.Lfunc_begin6
	.quad	.Ltmp64-.Lfunc_begin6
	.quad	.Ltmp65-.Lfunc_begin6
	.quad	.Ltmp66-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges35:
	.quad	.Ltmp68-.Lfunc_begin6
	.quad	.Ltmp69-.Lfunc_begin6
	.quad	.Ltmp70-.Lfunc_begin6
	.quad	.Ltmp71-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges36:
	.quad	.Ltmp69-.Lfunc_begin6
	.quad	.Ltmp70-.Lfunc_begin6
	.quad	.Ltmp71-.Lfunc_begin6
	.quad	.Ltmp72-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges37:
	.quad	.Ltmp73-.Lfunc_begin6
	.quad	.Ltmp74-.Lfunc_begin6
	.quad	.Ltmp75-.Lfunc_begin6
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges38:
	.quad	.Ltmp73-.Lfunc_begin6
	.quad	.Ltmp74-.Lfunc_begin6
	.quad	.Ltmp75-.Lfunc_begin6
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges39:
	.quad	.Ltmp84-.Lfunc_begin6
	.quad	.Ltmp93-.Lfunc_begin6
	.quad	.Ltmp94-.Lfunc_begin6
	.quad	.Ltmp96-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges40:
	.quad	.Ltmp84-.Lfunc_begin6
	.quad	.Ltmp91-.Lfunc_begin6
	.quad	.Ltmp92-.Lfunc_begin6
	.quad	.Ltmp93-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges41:
	.quad	.Ltmp90-.Lfunc_begin6
	.quad	.Ltmp91-.Lfunc_begin6
	.quad	.Ltmp92-.Lfunc_begin6
	.quad	.Ltmp93-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges42:
	.quad	.Ltmp91-.Lfunc_begin6
	.quad	.Ltmp92-.Lfunc_begin6
	.quad	.Ltmp94-.Lfunc_begin6
	.quad	.Ltmp95-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges43:
	.quad	.Ltmp91-.Lfunc_begin6
	.quad	.Ltmp92-.Lfunc_begin6
	.quad	.Ltmp94-.Lfunc_begin6
	.quad	.Ltmp95-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges44:
	.quad	.Ltmp91-.Lfunc_begin6
	.quad	.Ltmp92-.Lfunc_begin6
	.quad	.Ltmp94-.Lfunc_begin6
	.quad	.Ltmp95-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges45:
	.quad	.Ltmp97-.Lfunc_begin6
	.quad	.Ltmp106-.Lfunc_begin6
	.quad	.Ltmp107-.Lfunc_begin6
	.quad	.Ltmp109-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges46:
	.quad	.Ltmp97-.Lfunc_begin6
	.quad	.Ltmp104-.Lfunc_begin6
	.quad	.Ltmp105-.Lfunc_begin6
	.quad	.Ltmp106-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges47:
	.quad	.Ltmp103-.Lfunc_begin6
	.quad	.Ltmp104-.Lfunc_begin6
	.quad	.Ltmp105-.Lfunc_begin6
	.quad	.Ltmp106-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges48:
	.quad	.Ltmp104-.Lfunc_begin6
	.quad	.Ltmp105-.Lfunc_begin6
	.quad	.Ltmp107-.Lfunc_begin6
	.quad	.Ltmp108-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges49:
	.quad	.Ltmp104-.Lfunc_begin6
	.quad	.Ltmp105-.Lfunc_begin6
	.quad	.Ltmp107-.Lfunc_begin6
	.quad	.Ltmp108-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges50:
	.quad	.Ltmp104-.Lfunc_begin6
	.quad	.Ltmp105-.Lfunc_begin6
	.quad	.Ltmp107-.Lfunc_begin6
	.quad	.Ltmp108-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges51:
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges52:
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges53:
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges54:
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges55:
	.quad	.Ltmp76-.Lfunc_begin6
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	0
	.quad	0
.Ldebug_ranges56:
	.quad	.Ltmp77-.Lfunc_begin6
	.quad	.Ltmp78-.Lfunc_begin6
	.quad	.Ltmp79-.Lfunc_begin6
	.quad	.Ltmp81-.Lfunc_begin6
	.quad	0
	.quad	0
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"julia"                         ; string offset=0
.Linfo_string1:
	.asciz	"."                             ; string offset=6
.Linfo_string2:
	.asciz	"macro expansion;"              ; string offset=8
.Linfo_string3:
	.asciz	"pointerset;"                   ; string offset=25
.Linfo_string4:
	.asciz	"unsafe_store!;"                ; string offset=37
.Linfo_string5:
	.asciz	"setindex!;"                    ; string offset=52
.Linfo_string6:
	.asciz	"==;"                           ; string offset=63
.Linfo_string7:
	.asciz	"iterate;"                      ; string offset=67
.Linfo_string8:
	.asciz	"+;"                            ; string offset=76
.Linfo_string9:
	.asciz	"steprange_last_empty;"         ; string offset=79
.Linfo_string10:
	.asciz	"steprange_last;"               ; string offset=101
.Linfo_string11:
	.asciz	"StepRange;"                    ; string offset=117
.Linfo_string12:
	.asciz	"_colon;"                       ; string offset=128
.Linfo_string13:
	.asciz	"Colon;"                        ; string offset=136
.Linfo_string14:
	.asciz	"<;"                            ; string offset=143
.Linfo_string15:
	.asciz	">;"                            ; string offset=146
.Linfo_string16:
	.asciz	"isempty;"                      ; string offset=149
.Linfo_string17:
	.asciz	"bounded_uint;"                 ; string offset=158
.Linfo_string18:
	.asciz	"rem;"                          ; string offset=172
.Linfo_string19:
	.asciz	"mod;"                          ; string offset=177
.Linfo_string20:
	.asciz	"-;"                            ; string offset=182
.Linfo_string21:
	.asciz	"<<;"                           ; string offset=185
.Linfo_string22:
	.asciz	"rng_counter_key;"              ; string offset=189
.Linfo_string23:
	.asciz	"rng_words;"                    ; string offset=206
.Linfo_string24:
	.asciz	"rng_word;"                     ; string offset=217
.Linfo_string25:
	.asciz	"|;"                            ; string offset=227
.Linfo_string26:
	.asciz	"toUInt64;"                     ; string offset=230
.Linfo_string27:
	.asciz	"UInt64;"                       ; string offset=240
.Linfo_string28:
	.asciz	"convert;"                      ; string offset=248
.Linfo_string29:
	.asciz	"widen;"                        ; string offset=257
.Linfo_string30:
	.asciz	"widemul;"                      ; string offset=264
.Linfo_string31:
	.asciz	"_philox_round;"                ; string offset=273
.Linfo_string32:
	.asciz	"philox4x32_10;"                ; string offset=288
.Linfo_string33:
	.asciz	"*;"                            ; string offset=303
.Linfo_string34:
	.asciz	"xor;"                          ; string offset=306
.Linfo_string35:
	.asciz	"<=;"                           ; string offset=311
.Linfo_string36:
	.asciz	">=;"                           ; string offset=315
.Linfo_string37:
	.asciz	"toInt64;"                      ; string offset=319
.Linfo_string38:
	.asciz	"Int64;"                        ; string offset=328
.Linfo_string39:
	.asciz	"pointerref;"                   ; string offset=335
.Linfo_string40:
	.asciz	"unsafe_load;"                  ; string offset=347
.Linfo_string41:
	.asciz	"getindex;"                     ; string offset=360
.Linfo_string42:
	.asciz	"pack_exception;"               ; string offset=370
.Linfo_string43:
	.asciz	"signal_exception!;"            ; string offset=386
.Linfo_string44:
	.asciz	"signal_exception"              ; string offset=405
.Linfo_string45:
	.asciz	"llvm_atomic_cas;"              ; string offset=422
.Linfo_string46:
	.asciz	"kernel_state;"                 ; string offset=439
.Linfo_string47:
	.asciz	"endpgm;"                       ; string offset=453
.Linfo_string48:
	.asciz	"gpu__checkerboard_order_kernel!" ; string offset=461
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.section	".note.GNU-stack","",@progbits
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .name:           state
        .offset:         0
        .size:           40
        .value_kind:     by_value
      - .name:           '__ctx__::CompilerMetadata'
        .offset:         40
        .size:           16
        .value_kind:     by_value
      - .name:           'order::ROCDeviceArray'
        .offset:         56
        .size:           24
        .value_kind:     by_value
      - .name:           'seed::UInt64'
        .offset:         80
        .size:           8
        .value_kind:     by_value
      - .name:           'mcs::UInt64'
        .offset:         88
        .size:           8
        .value_kind:     by_value
      - .name:           'color_count::UInt32'
        .offset:         96
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 100
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_
    .private_segment_fixed_size: 0
    .sgpr_count:     52
    .sgpr_spill_count: 0
    .symbol:         _Z31gpu__checkerboard_order_kernel_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI4_1__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EE15Philox4x32x10V16UInt64SI_SF_.kd
    .uses_dynamic_stack: true
    .vgpr_count:     6
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target:   amdgcn-amd-amdhsa--gfx1100
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
	.section	.debug_line,"",@progbits
.Lline_table_start0:
