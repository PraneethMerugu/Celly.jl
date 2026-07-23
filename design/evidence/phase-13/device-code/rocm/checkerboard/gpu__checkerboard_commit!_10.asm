	.text
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1100"
	.amdhsa_code_object_version 5
	.protected	__ockl_devmem_request   ; -- Begin function __ockl_devmem_request
	.weak	__ockl_devmem_request
	.p2align	2
	.type	__ockl_devmem_request,@function
__ockl_devmem_request:                  ; @__ockl_devmem_request
.Lfunc_begin0:
	.cfi_sections .debug_frame
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
.Lfunc_end0:
	.size	__ockl_devmem_request, .Lfunc_end0-__ockl_devmem_request
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
.Lfunc_begin1:
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
.Lfunc_end1:
	.size	__ockl_hsa_signal_add, .Lfunc_end1-__ockl_hsa_signal_add
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
.Lfunc_begin2:
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
.Lfunc_end2:
	.size	__ockl_dm_init_v1, .Lfunc_end2-__ockl_dm_init_v1
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
.Lfunc_begin3:
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
.Lfunc_end3:
	.size	__ockl_dm_trim, .Lfunc_end3-__ockl_dm_trim
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
.Lfunc_begin4:
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
.Lfunc_end4:
	.size	__ockl_sanitizer_report, .Lfunc_end4-__ockl_sanitizer_report
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
	.globl	_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_ ; -- Begin function _Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_
	.p2align	8
	.type	_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_,@function
_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_: ; @_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_
.Lfunc_begin5:
	.file	1 "." "none"
	.loc	1 0 0                           ; none:0:0
	.cfi_startproc
; %bb.0:                                ; %conversion
	s_load_b64 s[4:5], s[0:1], 0x28
	v_add_nc_u32_e32 v0, 1, v0
	s_mov_b32 s2, s15
	s_mov_b32 s3, 0
	s_delay_alu instid0(SALU_CYCLE_1)
	s_lshl_b64 s[6:7], s[2:3], 8
	s_delay_alu instid0(VALU_DEP_1) | instid1(SALU_CYCLE_1)
	v_add_co_u32 v0, s2, s6, v0
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)
	v_add_co_ci_u32_e64 v1, null, s7, 0, s2
	s_mov_b32 s2, exec_lo
	s_waitcnt lgkmcnt(0)
	v_cmpx_ge_i64_e64 s[4:5], v[0:1]
	s_cbranch_execz .LBB5_13
; %bb.1:                                ; %L110
.Ltmp0:
	.file	2 "." "/home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl"
	.loc	2 39 0 prologue_end             ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x2
	s_load_b32 s2, s[0:1], 0x2b0
	s_load_b64 s[4:5], s[0:1], 0x40
	s_load_b64 s[6:7], s[0:1], 0x58
	s_waitcnt lgkmcnt(0)
	s_lshl_b64 s[8:9], s[2:3], 2
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_4) | instid1(SALU_CYCLE_1)
	s_add_u32 s4, s4, s8
	s_addc_u32 s5, s5, s9
	s_load_b32 s2, s[4:5], -0x4
.Ltmp1:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	s_lshl_b64 s[4:5], s[2:3], 2
	s_add_u32 s4, s6, s4
	s_addc_u32 s5, s7, s5
	s_load_b64 s[4:5], s[4:5], -0x4
.Ltmp2:
	.file	3 "." "int.jl"
	.loc	3 86 0 is_stmt 1                ; int.jl:86:0
	s_waitcnt lgkmcnt(0)
	s_sub_i32 s2, s5, s4
	s_delay_alu instid0(SALU_CYCLE_1)
.Ltmp3:
	.loc	3 521 0                         ; int.jl:521:0
	v_cmp_ge_u64_e32 vcc_lo, s[2:3], v[0:1]
.Ltmp4:
	.file	4 "." "/home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl"
	.loc	4 449 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:449:0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB5_13
; %bb.2:                                ; %L302
.Ltmp5:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_load_b64 s[2:3], s[0:1], 0x88
.Ltmp6:
	.loc	3 87 0                          ; int.jl:87:0
	v_add3_u32 v0, v0, s4, -1
.Ltmp7:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	global_load_u8 v1, v0, s[2:3] offset:-1
.Ltmp8:
	.file	5 "." "promotion.jl"
	.loc	5 637 0                         ; promotion.jl:637:0
	s_waitcnt vmcnt(0)
	v_cmp_eq_u16_e32 vcc_lo, 4, v1
.Ltmp9:
	.loc	4 451 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:451:0
	s_and_b32 exec_lo, exec_lo, vcc_lo
	s_cbranch_execz .LBB5_13
; %bb.3:                                ; %L328
.Ltmp10:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x2
	s_load_b64 s[2:3], s[0:1], 0x70
	s_load_b64 s[4:5], s[0:1], 0xa8
	s_load_b64 s[6:7], s[0:1], 0xc8
	s_waitcnt lgkmcnt(0)
	v_mad_u64_u32 v[4:5], null, 0x60, v0, s[2:3]
.Ltmp11:
	.loc	4 419 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:419:0
	s_mov_b32 s2, exec_lo
.Ltmp12:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x4
	global_load_b64 v[8:9], v[4:5], off offset:-96
	global_load_b128 v[0:3], v[4:5], off offset:-32
	global_load_u8 v12, v[4:5], off offset:-72
	global_load_b32 v13, v[4:5], off offset:-68
	global_load_b128 v[4:7], v[4:5], off offset:-16
.Ltmp13:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(4)
	v_lshlrev_b64 v[10:11], 2, v[8:9]
.Ltmp14:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v8, vcc_lo, s4, v8
	v_add_co_ci_u32_e32 v9, vcc_lo, s5, v9, vcc_lo
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_4)
.Ltmp15:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v10, vcc_lo, s6, v10
	v_add_co_ci_u32_e32 v11, vcc_lo, s7, v11, vcc_lo
.Ltmp16:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(2)
	global_store_b8 v[8:9], v12, off offset:-1
.Ltmp17:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(1)
	global_store_b32 v[10:11], v13, off offset:-4
.Ltmp18:
	.loc	5 637 0 is_stmt 1               ; promotion.jl:637:0
	v_cmpx_ne_u32_e32 0, v0
.Ltmp19:
	.loc	4 419 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:419:0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execz .LBB5_7
; %bb.4:                                ; %L408
.Ltmp20:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x1
	s_load_b64 s[4:5], s[0:1], 0x210
	s_load_b64 s[6:7], s[0:1], 0x240
.Ltmp21:
	.file	6 "." "boot.jl"
	.loc	6 936 0                         ; boot.jl:936:0
	v_dual_mov_b32 v9, 0 :: v_dual_mov_b32 v8, v0
.Ltmp22:
	.loc	4 423 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:423:0
	s_mov_b32 s3, exec_lo
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
.Ltmp23:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_lshlrev_b64 v[10:11], 2, v[8:9]
.Ltmp24:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_lshlrev_b64 v[14:15], 3, v[8:9]
.Ltmp25:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v12, vcc_lo, s4, v10
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_co_ci_u32_e32 v13, vcc_lo, s5, v11, vcc_lo
.Ltmp26:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v14, vcc_lo, s6, v14
	s_delay_alu instid0(VALU_DEP_4)
	v_add_co_ci_u32_e32 v15, vcc_lo, s7, v15, vcc_lo
.Ltmp27:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b32 v0, v[12:13], off offset:-4
.Ltmp28:
	.loc	3 86 0 is_stmt 1                ; int.jl:86:0
	s_waitcnt vmcnt(0)
	v_add_nc_u32_e32 v0, -1, v0
.Ltmp29:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b32 v[12:13], v0, off offset:-4
.Ltmp30:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b64 v[16:17], v[14:15], off offset:-8
.Ltmp31:
	.loc	3 87 0 is_stmt 1                ; int.jl:87:0
	s_waitcnt vmcnt(0)
	v_add_co_u32 v4, vcc_lo, v16, v4
	v_add_co_ci_u32_e32 v5, vcc_lo, v17, v5, vcc_lo
.Ltmp32:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b64 v[14:15], v[4:5], off offset:-8
.Ltmp33:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b32 v0, v[12:13], off offset:-4
.Ltmp34:
	.loc	5 637 0 is_stmt 1               ; promotion.jl:637:0
	s_waitcnt vmcnt(0)
	v_cmpx_eq_u32_e32 0, v0
.Ltmp35:
	.loc	4 423 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:423:0
	s_cbranch_execz .LBB5_6
; %bb.5:                                ; %L521
.Ltmp36:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x4
	s_load_b64 s[4:5], s[0:1], 0xe0
	s_load_b64 s[6:7], s[0:1], 0x110
	s_load_b64 s[8:9], s[0:1], 0x158
	s_load_b64 s[10:11], s[0:1], 0x2a0
	s_load_b64 s[12:13], s[0:1], 0x170
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v4, s4, s4, v8
.Ltmp37:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v12, vcc_lo, s6, v10
	v_add_co_ci_u32_e32 v13, vcc_lo, s7, v11, vcc_lo
.Ltmp38:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v14, vcc_lo, s8, v10
.Ltmp39:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_ci_u32_e64 v5, null, s5, 0, s4
.Ltmp40:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_ci_u32_e32 v15, vcc_lo, s9, v11, vcc_lo
.Ltmp41:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v10, vcc_lo, s12, v10
.Ltmp42:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_mov_b32_e32 v0, s10
.Ltmp43:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_ci_u32_e32 v11, vcc_lo, s13, v11, vcc_lo
.Ltmp44:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_mov_b32_e32 v8, s11
.Ltmp45:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b8 v[4:5], v9, off offset:-1
.Ltmp46:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b32 v[12:13], v9, off offset:-4
.Ltmp47:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b32 v[14:15], v0, off offset:-4
.Ltmp48:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b32 v[10:11], v8, off offset:-4
.Ltmp49:
.LBB5_6:                                ; %Flow33
	.loc	4 423 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:423:0
	s_or_b32 exec_lo, exec_lo, s3
.LBB5_7:                                ; %Flow34
	.loc	4 419 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:419:0
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB5_9
; %bb.8:                                ; %L613
.Ltmp50:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_load_b64 s[4:5], s[0:1], 0x228
.Ltmp51:
	.loc	6 881 0                         ; boot.jl:881:0
	s_waitcnt vmcnt(0)
	v_dual_mov_b32 v5, 0 :: v_dual_mov_b32 v4, v2
	v_mov_b32_e32 v0, 1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
.Ltmp52:
	.loc	3 88 0                          ; int.jl:88:0
	v_lshlrev_b64 v[4:5], 2, v[4:5]
.Ltmp53:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v4, vcc_lo, s4, v4
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v5, vcc_lo, s5, v5, vcc_lo
.Ltmp54:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt_vscnt null, 0x0
	global_atomic_sub_u32 v[4:5], v0, off offset:-4
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.Ltmp55:
.LBB5_9:                                ; %L641
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_or_b32 exec_lo, exec_lo, s2
	s_delay_alu instid0(SALU_CYCLE_1)
.Ltmp56:
	.loc	4 431 0 is_stmt 1               ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:431:0
	s_mov_b32 s2, exec_lo
.Ltmp57:
	.loc	5 637 0                         ; promotion.jl:637:0
	v_cmpx_ne_u32_e32 0, v1
.Ltmp58:
	.loc	4 431 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:431:0
	s_xor_b32 s2, exec_lo, s2
	s_cbranch_execz .LBB5_11
; %bb.10:                               ; %L647
.Ltmp59:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_clause 0x1
	s_load_b64 s[4:5], s[0:1], 0x210
	s_load_b64 s[6:7], s[0:1], 0x240
.Ltmp60:
	.loc	6 936 0                         ; boot.jl:936:0
	v_mov_b32_e32 v2, 0
.Ltmp61:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(0)
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)
	v_lshlrev_b64 v[3:4], 2, v[1:2]
.Ltmp62:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_lshlrev_b64 v[0:1], 3, v[1:2]
.Ltmp63:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v3, vcc_lo, s4, v3
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_co_ci_u32_e32 v4, vcc_lo, s5, v4, vcc_lo
.Ltmp64:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	v_add_co_u32 v0, vcc_lo, s6, v0
	s_delay_alu instid0(VALU_DEP_4)
	v_add_co_ci_u32_e32 v1, vcc_lo, s7, v1, vcc_lo
.Ltmp65:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b32 v5, v[3:4], off offset:-4
.Ltmp66:
	.loc	3 87 0 is_stmt 1                ; int.jl:87:0
	s_waitcnt vmcnt(0)
	v_add_nc_u32_e32 v2, 1, v5
.Ltmp67:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b32 v[3:4], v2, off offset:-4
.Ltmp68:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_load_b64 v[2:3], v[0:1], off offset:-8
.Ltmp69:
	.loc	3 87 0 is_stmt 1                ; int.jl:87:0
	s_waitcnt vmcnt(0)
	v_add_co_u32 v2, vcc_lo, v2, v6
	v_add_co_ci_u32_e32 v3, vcc_lo, v3, v7, vcc_lo
.Ltmp70:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	global_store_b64 v[0:1], v[2:3], off offset:-8
.Ltmp71:
                                        ; implicit-def: $vgpr0_vgpr1_vgpr2_vgpr3
.LBB5_11:                               ; %Flow
	.loc	4 431 0                         ; /home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/algorithms/checkerboard.jl:431:0
	s_and_not1_saveexec_b32 s2, s2
	s_cbranch_execz .LBB5_13
; %bb.12:                               ; %L737
.Ltmp72:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_load_b64 s[0:1], s[0:1], 0x228
.Ltmp73:
	.loc	6 881 0                         ; boot.jl:881:0
	v_dual_mov_b32 v1, 0 :: v_dual_mov_b32 v0, v3
	v_mov_b32_e32 v2, 1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)
.Ltmp74:
	.loc	3 88 0                          ; int.jl:88:0
	v_lshlrev_b64 v[0:1], 2, v[0:1]
.Ltmp75:
	.loc	2 39 0                          ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v0, vcc_lo, s0, v0
	s_delay_alu instid0(VALU_DEP_2)
	v_add_co_ci_u32_e32 v1, vcc_lo, s1, v1, vcc_lo
.Ltmp76:
	.loc	2 39 0 is_stmt 0                ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:39:0
	s_waitcnt vmcnt(0)
	s_waitcnt_vscnt null, 0x0
	global_atomic_add_u32 v[0:1], v2, off offset:-4
	s_waitcnt_vscnt null, 0x0
	buffer_gl0_inv
	buffer_gl1_inv
.Ltmp77:
.LBB5_13:                               ; %L767
	.loc	2 0 0                           ; /home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/base.jl:0:0
	s_nop 0
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	.file	7 "." "/home/praneeth/.julia/packages/KernelAbstractions/scVtc/src/macros.jl"
	.loc	7 332 0 is_stmt 1               ; /home/praneeth/.julia/packages/KernelAbstractions/scVtc/src/macros.jl:332:0
	s_endpgm
.Ltmp78:
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 692
		.amdhsa_user_sgpr_count 15
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_enable_private_segment 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 18
		.amdhsa_next_free_sgpr 16
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
.Lfunc_end5:
	.size	_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_, .Lfunc_end5-_Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_
	.cfi_endproc
	.file	8 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/device/gcn/array.jl"
	.file	9 "." "/home/praneeth/.julia/packages/LLVM/zkwaZ/src/interop/pointer.jl"
	.file	10 "." "operators.jl"
	.file	11 "." "number.jl"
	.file	12 "." "/home/praneeth/actions-runner/_work/Potts.jl/Potts.jl/_ci/source/lib/CorePotts/src/components/scientific_trackers.jl"
	.file	13 "." "/home/praneeth/.julia/packages/AMDGPU/cLA6g/src/AMDGPU.jl"
	.file	14 "." "/home/praneeth/.julia/packages/Atomix/7G0aL/src/references.jl"
	.file	15 "." "abstractarray.jl"
	.file	16 "." "/home/praneeth/.julia/packages/UnsafeAtomics/Mqknr/ext/UnsafeAtomicsLLVM/internal.jl"
	.file	17 "." "/home/praneeth/.julia/packages/UnsafeAtomics/Mqknr/ext/UnsafeAtomicsLLVM/atomics.jl"
                                        ; -- End function
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1064
; NumSgprs: 18
; NumVgprs: 18
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 2
; VGPRBlocks: 2
; NumSGPRsForWavesPerEU: 18
; NumVGPRsForWavesPerEU: 18
; Occupancy: 16
; WaveLimiterHint : 1
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 15
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 7, 3214868480
	.fill 96, 4, 3214868480
	.section	.debug_abbrev,"",@progbits
	.byte	1                               ; Abbreviation Code
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
	.byte	2                               ; Abbreviation Code
	.byte	46                              ; DW_TAG_subprogram
	.byte	0                               ; DW_CHILDREN_no
	.byte	3                               ; DW_AT_name
	.byte	14                              ; DW_FORM_strp
	.byte	32                              ; DW_AT_inline
	.byte	11                              ; DW_FORM_data1
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	3                               ; Abbreviation Code
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
	.byte	4                               ; Abbreviation Code
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
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	6                               ; Abbreviation Code
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
	.byte	5                               ; DW_FORM_data2
	.byte	0                               ; EOM(1)
	.byte	0                               ; EOM(2)
	.byte	8                               ; Abbreviation Code
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
	.byte	0                               ; EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.long	.Ldebug_info_end0-.Ldebug_info_start0 ; Length of Unit
.Ldebug_info_start0:
	.short	4                               ; DWARF version number
	.long	.debug_abbrev                   ; Offset Into Abbrev. Section
	.byte	8                               ; Address Size (in bytes)
	.byte	1                               ; Abbrev [1] 0xb:0xb3b DW_TAG_compile_unit
	.long	.Linfo_string0                  ; DW_AT_producer
	.short	31                              ; DW_AT_language
	.long	.Linfo_string0                  ; DW_AT_name
	.long	.Lline_table_start0             ; DW_AT_stmt_list
	.long	.Linfo_string1                  ; DW_AT_comp_dir
	.quad	.Lfunc_begin5                   ; DW_AT_low_pc
	.long	.Lfunc_end5-.Lfunc_begin5       ; DW_AT_high_pc
	.byte	2                               ; Abbrev [2] 0x2a:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x30:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x36:0x6 DW_TAG_subprogram
	.long	.Linfo_string3                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x3c:0x6 DW_TAG_subprogram
	.long	.Linfo_string4                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x42:0x6 DW_TAG_subprogram
	.long	.Linfo_string5                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x48:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x4e:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x54:0x6 DW_TAG_subprogram
	.long	.Linfo_string6                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x5a:0x6 DW_TAG_subprogram
	.long	.Linfo_string7                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x60:0x6 DW_TAG_subprogram
	.long	.Linfo_string7                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x66:0x6 DW_TAG_subprogram
	.long	.Linfo_string8                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x6c:0x6 DW_TAG_subprogram
	.long	.Linfo_string9                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x72:0x6 DW_TAG_subprogram
	.long	.Linfo_string10                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x78:0x6 DW_TAG_subprogram
	.long	.Linfo_string11                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x7e:0x6 DW_TAG_subprogram
	.long	.Linfo_string12                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x84:0x6 DW_TAG_subprogram
	.long	.Linfo_string13                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x8a:0x6 DW_TAG_subprogram
	.long	.Linfo_string9                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x90:0x6 DW_TAG_subprogram
	.long	.Linfo_string14                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x96:0x6 DW_TAG_subprogram
	.long	.Linfo_string15                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x9c:0x6 DW_TAG_subprogram
	.long	.Linfo_string16                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xa2:0x6 DW_TAG_subprogram
	.long	.Linfo_string17                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xa8:0x6 DW_TAG_subprogram
	.long	.Linfo_string18                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xae:0x6 DW_TAG_subprogram
	.long	.Linfo_string19                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xb4:0x6 DW_TAG_subprogram
	.long	.Linfo_string20                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xba:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xc0:0x6 DW_TAG_subprogram
	.long	.Linfo_string21                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xc6:0x6 DW_TAG_subprogram
	.long	.Linfo_string8                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xcc:0x6 DW_TAG_subprogram
	.long	.Linfo_string22                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xd2:0x6 DW_TAG_subprogram
	.long	.Linfo_string22                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xd8:0x6 DW_TAG_subprogram
	.long	.Linfo_string23                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xde:0x6 DW_TAG_subprogram
	.long	.Linfo_string24                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xe4:0x6 DW_TAG_subprogram
	.long	.Linfo_string25                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xea:0x6 DW_TAG_subprogram
	.long	.Linfo_string26                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xf0:0x6 DW_TAG_subprogram
	.long	.Linfo_string27                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xf6:0x6 DW_TAG_subprogram
	.long	.Linfo_string2                  ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0xfc:0x6 DW_TAG_subprogram
	.long	.Linfo_string28                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x102:0x6 DW_TAG_subprogram
	.long	.Linfo_string29                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	2                               ; Abbrev [2] 0x108:0x6 DW_TAG_subprogram
	.long	.Linfo_string23                 ; DW_AT_name
	.byte	1                               ; DW_AT_inline
	.byte	3                               ; Abbrev [3] 0x10e:0xa37 DW_TAG_subprogram
	.quad	.Lfunc_begin5                   ; DW_AT_low_pc
	.long	.Lfunc_end5-.Lfunc_begin5       ; DW_AT_high_pc
	.long	.Linfo_string30                 ; DW_AT_name
	.byte	4                               ; Abbrev [4] 0x11f:0xa25 DW_TAG_inlined_subroutine
	.long	78                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp78-.Ltmp0                  ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x132:0xa11 DW_TAG_inlined_subroutine
	.long	72                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp0                  ; DW_AT_high_pc
	.byte	7                               ; DW_AT_call_file
	.short	332                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x146:0x64 DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp1-.Ltmp0                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	445                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x15a:0x4f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp1-.Ltmp0                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x16d:0x3b DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp1-.Ltmp0                   ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x180:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp1-.Ltmp0                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x193:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp0                          ; DW_AT_low_pc
	.long	.Ltmp1-.Ltmp0                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x1aa:0x64 DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	446                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x1be:0x4f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x1d1:0x3b DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x1e4:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x1f7:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp1                          ; DW_AT_low_pc
	.long	.Ltmp2-.Ltmp1                   ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x20e:0x14 DW_TAG_inlined_subroutine
	.long	84                              ; DW_AT_abstract_origin
	.quad	.Ltmp2                          ; DW_AT_low_pc
	.long	.Ltmp3-.Ltmp2                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	448                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x222:0x3e DW_TAG_inlined_subroutine
	.long	90                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	449                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x236:0x29 DW_TAG_inlined_subroutine
	.long	96                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	3                               ; DW_AT_call_file
	.short	527                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x24a:0x14 DW_TAG_inlined_subroutine
	.long	90                              ; DW_AT_abstract_origin
	.quad	.Ltmp3                          ; DW_AT_low_pc
	.long	.Ltmp4-.Ltmp3                   ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	489                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x260:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges0                 ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	451                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x26c:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges1                 ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x277:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges2                 ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x282:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges3                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x28d:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges4                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x29c:0x14 DW_TAG_inlined_subroutine
	.long	102                             ; DW_AT_abstract_origin
	.quad	.Ltmp6                          ; DW_AT_low_pc
	.long	.Ltmp7-.Ltmp6                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	450                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x2b0:0x14 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp8                          ; DW_AT_low_pc
	.long	.Ltmp9-.Ltmp8                   ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	451                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x2c4:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges5                 ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	453                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x2d0:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges6                 ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x2db:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges7                 ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x2e6:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges8                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x2f1:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges9                 ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x300:0x842 DW_TAG_inlined_subroutine
	.long	114                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges10                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	454                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x30c:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges11                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	418                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x318:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges12                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x323:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges13                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x32e:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges14                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x339:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges15                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x348:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges16                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	417                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x354:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges17                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x35f:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges18                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x36a:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges19                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x375:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges20                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x384:0xa2 DW_TAG_inlined_subroutine
	.long	144                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges21                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	419                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x390:0x95 DW_TAG_inlined_subroutine
	.long	138                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges22                ; DW_AT_ranges
	.byte	10                              ; DW_AT_call_file
	.short	321                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x39c:0x88 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges23                ; DW_AT_ranges
	.byte	3                               ; DW_AT_call_file
	.short	524                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x3a8:0x14 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp18                         ; DW_AT_low_pc
	.long	.Ltmp19-.Ltmp18                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	487                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x3bc:0x67 DW_TAG_inlined_subroutine
	.long	174                             ; DW_AT_abstract_origin
	.quad	.Ltmp21                         ; DW_AT_low_pc
	.long	.Ltmp22-.Ltmp21                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	487                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x3d0:0x52 DW_TAG_inlined_subroutine
	.long	168                             ; DW_AT_abstract_origin
	.quad	.Ltmp21                         ; DW_AT_low_pc
	.long	.Ltmp22-.Ltmp21                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	404                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x3e4:0x3d DW_TAG_inlined_subroutine
	.long	162                             ; DW_AT_abstract_origin
	.quad	.Ltmp21                         ; DW_AT_low_pc
	.long	.Ltmp22-.Ltmp21                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	379                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x3f8:0x28 DW_TAG_inlined_subroutine
	.long	156                             ; DW_AT_abstract_origin
	.quad	.Ltmp21                         ; DW_AT_low_pc
	.long	.Ltmp22-.Ltmp21                 ; DW_AT_high_pc
	.byte	11                              ; DW_AT_call_file
	.byte	7                               ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x40b:0x14 DW_TAG_inlined_subroutine
	.long	150                             ; DW_AT_abstract_origin
	.quad	.Ltmp21                         ; DW_AT_low_pc
	.long	.Ltmp22-.Ltmp21                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	962                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x426:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges24                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	421                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x432:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges25                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x43d:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges26                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x448:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges27                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x453:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges28                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x462:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges29                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	422                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x46e:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges30                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x479:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges31                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x484:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges32                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x48f:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges33                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x49e:0x14 DW_TAG_inlined_subroutine
	.long	84                              ; DW_AT_abstract_origin
	.quad	.Ltmp28                         ; DW_AT_low_pc
	.long	.Ltmp29-.Ltmp28                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	421                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x4b2:0x64 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp29                         ; DW_AT_low_pc
	.long	.Ltmp30-.Ltmp29                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	421                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x4c6:0x4f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.quad	.Ltmp29                         ; DW_AT_low_pc
	.long	.Ltmp30-.Ltmp29                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x4d9:0x3b DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.quad	.Ltmp29                         ; DW_AT_low_pc
	.long	.Ltmp30-.Ltmp29                 ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x4ec:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp29                         ; DW_AT_low_pc
	.long	.Ltmp30-.Ltmp29                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x4ff:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp29                         ; DW_AT_low_pc
	.long	.Ltmp30-.Ltmp29                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x516:0x14 DW_TAG_inlined_subroutine
	.long	102                             ; DW_AT_abstract_origin
	.quad	.Ltmp31                         ; DW_AT_low_pc
	.long	.Ltmp32-.Ltmp31                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	422                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x52a:0x64 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp32                         ; DW_AT_low_pc
	.long	.Ltmp33-.Ltmp32                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	422                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x53e:0x4f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.quad	.Ltmp32                         ; DW_AT_low_pc
	.long	.Ltmp33-.Ltmp32                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x551:0x3b DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.quad	.Ltmp32                         ; DW_AT_low_pc
	.long	.Ltmp33-.Ltmp32                 ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x564:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp32                         ; DW_AT_low_pc
	.long	.Ltmp33-.Ltmp32                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x577:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp32                         ; DW_AT_low_pc
	.long	.Ltmp33-.Ltmp32                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x58e:0x64 DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.quad	.Ltmp33                         ; DW_AT_low_pc
	.long	.Ltmp34-.Ltmp33                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	423                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x5a2:0x4f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.quad	.Ltmp33                         ; DW_AT_low_pc
	.long	.Ltmp34-.Ltmp33                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x5b5:0x3b DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.quad	.Ltmp33                         ; DW_AT_low_pc
	.long	.Ltmp34-.Ltmp33                 ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x5c8:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp33                         ; DW_AT_low_pc
	.long	.Ltmp34-.Ltmp33                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x5db:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp33                         ; DW_AT_low_pc
	.long	.Ltmp34-.Ltmp33                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x5f2:0x29 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp34                         ; DW_AT_low_pc
	.long	.Ltmp35-.Ltmp34                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	423                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x606:0x14 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp34                         ; DW_AT_low_pc
	.long	.Ltmp35-.Ltmp34                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	487                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x61b:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges34                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	424                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x627:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges35                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x632:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges36                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x63d:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges37                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x648:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges38                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x657:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges39                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	425                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x663:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges40                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x66e:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges41                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x679:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges42                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x684:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges43                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x693:0x92 DW_TAG_inlined_subroutine
	.long	180                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges44                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	426                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x69f:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges45                ; DW_AT_ranges
	.byte	12                              ; DW_AT_call_file
	.short	331                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x6ab:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges46                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x6b6:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges47                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x6c1:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges48                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x6cc:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges49                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x6db:0x49 DW_TAG_inlined_subroutine
	.long	180                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges50                ; DW_AT_ranges
	.byte	12                              ; DW_AT_call_file
	.short	332                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x6e7:0x3c DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges51                ; DW_AT_ranges
	.byte	12                              ; DW_AT_call_file
	.short	331                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x6f3:0x2f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges52                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x6fe:0x23 DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges53                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x709:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges54                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x714:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges55                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x725:0xe0 DW_TAG_inlined_subroutine
	.long	216                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges56                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	429                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x731:0x6f DW_TAG_inlined_subroutine
	.long	210                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges57                ; DW_AT_ranges
	.byte	13                              ; DW_AT_call_file
	.byte	141                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x73c:0x63 DW_TAG_inlined_subroutine
	.long	204                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges58                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.byte	99                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x747:0x2f DW_TAG_inlined_subroutine
	.long	198                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges59                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	61                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x752:0x23 DW_TAG_inlined_subroutine
	.long	192                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges60                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	149                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x75d:0x17 DW_TAG_inlined_subroutine
	.long	186                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges61                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	116                             ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x768:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges62                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	116                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x776:0x28 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.quad	.Ltmp52                         ; DW_AT_low_pc
	.long	.Ltmp53-.Ltmp52                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	61                              ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x789:0x14 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp52                         ; DW_AT_low_pc
	.long	.Ltmp53-.Ltmp52                 ; DW_AT_high_pc
	.byte	15                              ; DW_AT_call_file
	.short	1262                            ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0x7a0:0x64 DW_TAG_inlined_subroutine
	.long	264                             ; DW_AT_abstract_origin
	.quad	.Ltmp54                         ; DW_AT_low_pc
	.long	.Ltmp55-.Ltmp54                 ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.byte	143                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x7b3:0x50 DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.quad	.Ltmp54                         ; DW_AT_low_pc
	.long	.Ltmp55-.Ltmp54                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	23                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x7c6:0x3c DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp54                         ; DW_AT_low_pc
	.long	.Ltmp55-.Ltmp54                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.short	303                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x7da:0x27 DW_TAG_inlined_subroutine
	.long	246                             ; DW_AT_abstract_origin
	.quad	.Ltmp54                         ; DW_AT_low_pc
	.long	.Ltmp55-.Ltmp54                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.byte	213                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x7ed:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp54                         ; DW_AT_low_pc
	.long	.Ltmp55-.Ltmp54                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.byte	213                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0x805:0x29 DW_TAG_inlined_subroutine
	.long	228                             ; DW_AT_abstract_origin
	.quad	.Ltmp51                         ; DW_AT_low_pc
	.long	.Ltmp52-.Ltmp51                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	429                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x819:0x14 DW_TAG_inlined_subroutine
	.long	222                             ; DW_AT_abstract_origin
	.quad	.Ltmp51                         ; DW_AT_low_pc
	.long	.Ltmp52-.Ltmp51                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	957                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x82e:0xa2 DW_TAG_inlined_subroutine
	.long	144                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges63                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	431                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x83a:0x95 DW_TAG_inlined_subroutine
	.long	138                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges64                ; DW_AT_ranges
	.byte	10                              ; DW_AT_call_file
	.short	321                             ; DW_AT_call_line
	.byte	8                               ; Abbrev [8] 0x846:0x88 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges65                ; DW_AT_ranges
	.byte	3                               ; DW_AT_call_file
	.short	524                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x852:0x14 DW_TAG_inlined_subroutine
	.long	108                             ; DW_AT_abstract_origin
	.quad	.Ltmp57                         ; DW_AT_low_pc
	.long	.Ltmp58-.Ltmp57                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	487                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x866:0x67 DW_TAG_inlined_subroutine
	.long	174                             ; DW_AT_abstract_origin
	.quad	.Ltmp60                         ; DW_AT_low_pc
	.long	.Ltmp61-.Ltmp60                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	487                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x87a:0x52 DW_TAG_inlined_subroutine
	.long	168                             ; DW_AT_abstract_origin
	.quad	.Ltmp60                         ; DW_AT_low_pc
	.long	.Ltmp61-.Ltmp60                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	404                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x88e:0x3d DW_TAG_inlined_subroutine
	.long	162                             ; DW_AT_abstract_origin
	.quad	.Ltmp60                         ; DW_AT_low_pc
	.long	.Ltmp61-.Ltmp60                 ; DW_AT_high_pc
	.byte	5                               ; DW_AT_call_file
	.short	379                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x8a2:0x28 DW_TAG_inlined_subroutine
	.long	156                             ; DW_AT_abstract_origin
	.quad	.Ltmp60                         ; DW_AT_low_pc
	.long	.Ltmp61-.Ltmp60                 ; DW_AT_high_pc
	.byte	11                              ; DW_AT_call_file
	.byte	7                               ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0x8b5:0x14 DW_TAG_inlined_subroutine
	.long	150                             ; DW_AT_abstract_origin
	.quad	.Ltmp60                         ; DW_AT_low_pc
	.long	.Ltmp61-.Ltmp60                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	962                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x8d0:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges66                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	433                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x8dc:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges67                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x8e7:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges68                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x8f2:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges69                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x8fd:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges70                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0x90c:0x3c DW_TAG_inlined_subroutine
	.long	66                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges71                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	434                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x918:0x2f DW_TAG_inlined_subroutine
	.long	60                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges72                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	81                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x923:0x23 DW_TAG_inlined_subroutine
	.long	54                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges73                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	87                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0x92e:0x17 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges74                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0x939:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges75                ; DW_AT_ranges
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x948:0x14 DW_TAG_inlined_subroutine
	.long	102                             ; DW_AT_abstract_origin
	.quad	.Ltmp66                         ; DW_AT_low_pc
	.long	.Ltmp67-.Ltmp66                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	433                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x95c:0x64 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp67                         ; DW_AT_low_pc
	.long	.Ltmp68-.Ltmp67                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	433                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x970:0x4f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.quad	.Ltmp67                         ; DW_AT_low_pc
	.long	.Ltmp68-.Ltmp67                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x983:0x3b DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.quad	.Ltmp67                         ; DW_AT_low_pc
	.long	.Ltmp68-.Ltmp67                 ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x996:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp67                         ; DW_AT_low_pc
	.long	.Ltmp68-.Ltmp67                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0x9a9:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp67                         ; DW_AT_low_pc
	.long	.Ltmp68-.Ltmp67                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	7                               ; Abbrev [7] 0x9c0:0x14 DW_TAG_inlined_subroutine
	.long	102                             ; DW_AT_abstract_origin
	.quad	.Ltmp69                         ; DW_AT_low_pc
	.long	.Ltmp70-.Ltmp69                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	434                             ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0x9d4:0x64 DW_TAG_inlined_subroutine
	.long	132                             ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp71-.Ltmp70                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	434                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x9e8:0x4f DW_TAG_inlined_subroutine
	.long	126                             ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp71-.Ltmp70                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	86                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0x9fb:0x3b DW_TAG_inlined_subroutine
	.long	120                             ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp71-.Ltmp70                 ; DW_AT_high_pc
	.byte	9                               ; DW_AT_call_file
	.byte	90                              ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0xa0e:0x27 DW_TAG_inlined_subroutine
	.long	48                              ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp71-.Ltmp70                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0xa21:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp70                         ; DW_AT_low_pc
	.long	.Ltmp71-.Ltmp70                 ; DW_AT_high_pc
	.byte	1                               ; DW_AT_call_file
	.byte	0                               ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	8                               ; Abbrev [8] 0xa38:0xe0 DW_TAG_inlined_subroutine
	.long	216                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges76                ; DW_AT_ranges
	.byte	4                               ; DW_AT_call_file
	.short	436                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa44:0x6f DW_TAG_inlined_subroutine
	.long	210                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges77                ; DW_AT_ranges
	.byte	13                              ; DW_AT_call_file
	.byte	141                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa4f:0x63 DW_TAG_inlined_subroutine
	.long	204                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges78                ; DW_AT_ranges
	.byte	14                              ; DW_AT_call_file
	.byte	99                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa5a:0x2f DW_TAG_inlined_subroutine
	.long	198                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges79                ; DW_AT_ranges
	.byte	8                               ; DW_AT_call_file
	.byte	61                              ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa65:0x23 DW_TAG_inlined_subroutine
	.long	192                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges80                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	149                             ; DW_AT_call_line
	.byte	9                               ; Abbrev [9] 0xa70:0x17 DW_TAG_inlined_subroutine
	.long	186                             ; DW_AT_abstract_origin
	.long	.Ldebug_ranges81                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	116                             ; DW_AT_call_line
	.byte	10                              ; Abbrev [10] 0xa7b:0xb DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.long	.Ldebug_ranges82                ; DW_AT_ranges
	.byte	9                               ; DW_AT_call_file
	.byte	116                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xa89:0x28 DW_TAG_inlined_subroutine
	.long	240                             ; DW_AT_abstract_origin
	.quad	.Ltmp74                         ; DW_AT_low_pc
	.long	.Ltmp75-.Ltmp74                 ; DW_AT_high_pc
	.byte	8                               ; DW_AT_call_file
	.byte	61                              ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0xa9c:0x14 DW_TAG_inlined_subroutine
	.long	234                             ; DW_AT_abstract_origin
	.quad	.Ltmp74                         ; DW_AT_low_pc
	.long	.Ltmp75-.Ltmp74                 ; DW_AT_high_pc
	.byte	15                              ; DW_AT_call_file
	.short	1262                            ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	4                               ; Abbrev [4] 0xab3:0x64 DW_TAG_inlined_subroutine
	.long	264                             ; DW_AT_abstract_origin
	.quad	.Ltmp76                         ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp76                 ; DW_AT_high_pc
	.byte	13                              ; DW_AT_call_file
	.byte	143                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0xac6:0x50 DW_TAG_inlined_subroutine
	.long	258                             ; DW_AT_abstract_origin
	.quad	.Ltmp76                         ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp76                 ; DW_AT_high_pc
	.byte	16                              ; DW_AT_call_file
	.byte	23                              ; DW_AT_call_line
	.byte	5                               ; Abbrev [5] 0xad9:0x3c DW_TAG_inlined_subroutine
	.long	252                             ; DW_AT_abstract_origin
	.quad	.Ltmp76                         ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp76                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.short	303                             ; DW_AT_call_line
	.byte	4                               ; Abbrev [4] 0xaed:0x27 DW_TAG_inlined_subroutine
	.long	246                             ; DW_AT_abstract_origin
	.quad	.Ltmp76                         ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp76                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.byte	213                             ; DW_AT_call_line
	.byte	6                               ; Abbrev [6] 0xb00:0x13 DW_TAG_inlined_subroutine
	.long	42                              ; DW_AT_abstract_origin
	.quad	.Ltmp76                         ; DW_AT_low_pc
	.long	.Ltmp77-.Ltmp76                 ; DW_AT_high_pc
	.byte	17                              ; DW_AT_call_file
	.byte	213                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	5                               ; Abbrev [5] 0xb18:0x29 DW_TAG_inlined_subroutine
	.long	228                             ; DW_AT_abstract_origin
	.quad	.Ltmp73                         ; DW_AT_low_pc
	.long	.Ltmp74-.Ltmp73                 ; DW_AT_high_pc
	.byte	4                               ; DW_AT_call_file
	.short	436                             ; DW_AT_call_line
	.byte	7                               ; Abbrev [7] 0xb2c:0x14 DW_TAG_inlined_subroutine
	.long	222                             ; DW_AT_abstract_origin
	.quad	.Ltmp73                         ; DW_AT_low_pc
	.long	.Ltmp74-.Ltmp73                 ; DW_AT_high_pc
	.byte	6                               ; DW_AT_call_file
	.short	957                             ; DW_AT_call_line
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
	.byte	0                               ; End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.quad	.Ltmp5-.Lfunc_begin5
	.quad	.Ltmp6-.Lfunc_begin5
	.quad	.Ltmp7-.Lfunc_begin5
	.quad	.Ltmp8-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges1:
	.quad	.Ltmp5-.Lfunc_begin5
	.quad	.Ltmp6-.Lfunc_begin5
	.quad	.Ltmp7-.Lfunc_begin5
	.quad	.Ltmp8-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges2:
	.quad	.Ltmp5-.Lfunc_begin5
	.quad	.Ltmp6-.Lfunc_begin5
	.quad	.Ltmp7-.Lfunc_begin5
	.quad	.Ltmp8-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges3:
	.quad	.Ltmp5-.Lfunc_begin5
	.quad	.Ltmp6-.Lfunc_begin5
	.quad	.Ltmp7-.Lfunc_begin5
	.quad	.Ltmp8-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges4:
	.quad	.Ltmp5-.Lfunc_begin5
	.quad	.Ltmp6-.Lfunc_begin5
	.quad	.Ltmp7-.Lfunc_begin5
	.quad	.Ltmp8-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges5:
	.quad	.Ltmp10-.Lfunc_begin5
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges6:
	.quad	.Ltmp10-.Lfunc_begin5
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges7:
	.quad	.Ltmp10-.Lfunc_begin5
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges8:
	.quad	.Ltmp10-.Lfunc_begin5
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges9:
	.quad	.Ltmp10-.Lfunc_begin5
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges10:
	.quad	.Ltmp11-.Lfunc_begin5
	.quad	.Ltmp12-.Lfunc_begin5
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	.Ltmp56-.Lfunc_begin5
	.quad	.Ltmp77-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges11:
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges12:
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges13:
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges14:
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges15:
	.quad	.Ltmp13-.Lfunc_begin5
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges16:
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges17:
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges18:
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges19:
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges20:
	.quad	.Ltmp14-.Lfunc_begin5
	.quad	.Ltmp15-.Lfunc_begin5
	.quad	.Ltmp16-.Lfunc_begin5
	.quad	.Ltmp17-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges21:
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	.Ltmp19-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp22-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges22:
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	.Ltmp19-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp22-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges23:
	.quad	.Ltmp18-.Lfunc_begin5
	.quad	.Ltmp19-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp22-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges24:
	.quad	.Ltmp20-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp23-.Lfunc_begin5
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp28-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges25:
	.quad	.Ltmp20-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp23-.Lfunc_begin5
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp28-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges26:
	.quad	.Ltmp20-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp23-.Lfunc_begin5
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp28-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges27:
	.quad	.Ltmp20-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp23-.Lfunc_begin5
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp28-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges28:
	.quad	.Ltmp20-.Lfunc_begin5
	.quad	.Ltmp21-.Lfunc_begin5
	.quad	.Ltmp23-.Lfunc_begin5
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp28-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges29:
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp30-.Lfunc_begin5
	.quad	.Ltmp31-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges30:
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp30-.Lfunc_begin5
	.quad	.Ltmp31-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges31:
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp30-.Lfunc_begin5
	.quad	.Ltmp31-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges32:
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp30-.Lfunc_begin5
	.quad	.Ltmp31-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges33:
	.quad	.Ltmp24-.Lfunc_begin5
	.quad	.Ltmp25-.Lfunc_begin5
	.quad	.Ltmp26-.Lfunc_begin5
	.quad	.Ltmp27-.Lfunc_begin5
	.quad	.Ltmp30-.Lfunc_begin5
	.quad	.Ltmp31-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges34:
	.quad	.Ltmp36-.Lfunc_begin5
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges35:
	.quad	.Ltmp36-.Lfunc_begin5
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges36:
	.quad	.Ltmp36-.Lfunc_begin5
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges37:
	.quad	.Ltmp36-.Lfunc_begin5
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges38:
	.quad	.Ltmp36-.Lfunc_begin5
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges39:
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges40:
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges41:
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges42:
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges43:
	.quad	.Ltmp37-.Lfunc_begin5
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp46-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges44:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges45:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges46:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges47:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges48:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges49:
	.quad	.Ltmp38-.Lfunc_begin5
	.quad	.Ltmp39-.Lfunc_begin5
	.quad	.Ltmp40-.Lfunc_begin5
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp45-.Lfunc_begin5
	.quad	.Ltmp47-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges50:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges51:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges52:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges53:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges54:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges55:
	.quad	.Ltmp41-.Lfunc_begin5
	.quad	.Ltmp42-.Lfunc_begin5
	.quad	.Ltmp43-.Lfunc_begin5
	.quad	.Ltmp44-.Lfunc_begin5
	.quad	.Ltmp48-.Lfunc_begin5
	.quad	.Ltmp49-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges56:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp52-.Lfunc_begin5
	.quad	.Ltmp55-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges57:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp52-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges58:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp52-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges59:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp53-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges60:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp53-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges61:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp53-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges62:
	.quad	.Ltmp50-.Lfunc_begin5
	.quad	.Ltmp51-.Lfunc_begin5
	.quad	.Ltmp53-.Lfunc_begin5
	.quad	.Ltmp54-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges63:
	.quad	.Ltmp57-.Lfunc_begin5
	.quad	.Ltmp58-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges64:
	.quad	.Ltmp57-.Lfunc_begin5
	.quad	.Ltmp58-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges65:
	.quad	.Ltmp57-.Lfunc_begin5
	.quad	.Ltmp58-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges66:
	.quad	.Ltmp59-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp66-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges67:
	.quad	.Ltmp59-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp66-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges68:
	.quad	.Ltmp59-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp66-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges69:
	.quad	.Ltmp59-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp66-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges70:
	.quad	.Ltmp59-.Lfunc_begin5
	.quad	.Ltmp60-.Lfunc_begin5
	.quad	.Ltmp61-.Lfunc_begin5
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp66-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges71:
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp68-.Lfunc_begin5
	.quad	.Ltmp69-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges72:
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp68-.Lfunc_begin5
	.quad	.Ltmp69-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges73:
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp68-.Lfunc_begin5
	.quad	.Ltmp69-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges74:
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp68-.Lfunc_begin5
	.quad	.Ltmp69-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges75:
	.quad	.Ltmp62-.Lfunc_begin5
	.quad	.Ltmp63-.Lfunc_begin5
	.quad	.Ltmp64-.Lfunc_begin5
	.quad	.Ltmp65-.Lfunc_begin5
	.quad	.Ltmp68-.Lfunc_begin5
	.quad	.Ltmp69-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges76:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp74-.Lfunc_begin5
	.quad	.Ltmp77-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges77:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp74-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges78:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp74-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges79:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp75-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges80:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp75-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges81:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp75-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
	.quad	0
	.quad	0
.Ldebug_ranges82:
	.quad	.Ltmp72-.Lfunc_begin5
	.quad	.Ltmp73-.Lfunc_begin5
	.quad	.Ltmp75-.Lfunc_begin5
	.quad	.Ltmp76-.Lfunc_begin5
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
	.asciz	"pointerref;"                   ; string offset=25
.Linfo_string4:
	.asciz	"unsafe_load;"                  ; string offset=37
.Linfo_string5:
	.asciz	"getindex;"                     ; string offset=50
.Linfo_string6:
	.asciz	"-;"                            ; string offset=60
.Linfo_string7:
	.asciz	"<=;"                           ; string offset=63
.Linfo_string8:
	.asciz	"+;"                            ; string offset=67
.Linfo_string9:
	.asciz	"==;"                           ; string offset=70
.Linfo_string10:
	.asciz	"_commit_checkerboard!;"        ; string offset=74
.Linfo_string11:
	.asciz	"pointerset;"                   ; string offset=97
.Linfo_string12:
	.asciz	"unsafe_store!;"                ; string offset=109
.Linfo_string13:
	.asciz	"setindex!;"                    ; string offset=124
.Linfo_string14:
	.asciz	"!=;"                           ; string offset=135
.Linfo_string15:
	.asciz	"toUInt64;"                     ; string offset=139
.Linfo_string16:
	.asciz	"UInt64;"                       ; string offset=149
.Linfo_string17:
	.asciz	"convert;"                      ; string offset=157
.Linfo_string18:
	.asciz	"_promote;"                     ; string offset=166
.Linfo_string19:
	.asciz	"promote;"                      ; string offset=176
.Linfo_string20:
	.asciz	"_reset_columns!;"              ; string offset=185
.Linfo_string21:
	.asciz	"add_ptr;"                      ; string offset=202
.Linfo_string22:
	.asciz	"pointer;"                      ; string offset=211
.Linfo_string23:
	.asciz	"modify!;"                      ; string offset=220
.Linfo_string24:
	.asciz	"toInt64;"                      ; string offset=229
.Linfo_string25:
	.asciz	"Int64;"                        ; string offset=238
.Linfo_string26:
	.asciz	"*;"                            ; string offset=245
.Linfo_string27:
	.asciz	"_memory_offset;"               ; string offset=248
.Linfo_string28:
	.asciz	"llvm_atomic_op;"               ; string offset=264
.Linfo_string29:
	.asciz	"atomic_pointermodify;"         ; string offset=280
.Linfo_string30:
	.asciz	"gpu__checkerboard_commit!"     ; string offset=302
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
	.ident	"clang version 18.1.8 (Fedora 18.1.8-5.fc41)"
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
      - .name:           'color_order::ROCDeviceArray'
        .offset:         56
        .size:           24
        .value_kind:     by_value
      - .name:           'color_offsets::ROCDeviceArray'
        .offset:         80
        .size:           24
        .value_kind:     by_value
      - .name:           'transactions::ROCDeviceArray'
        .offset:         104
        .size:           24
        .value_kind:     by_value
      - .name:           'dispositions::ROCDeviceArray'
        .offset:         128
        .size:           24
        .value_kind:     by_value
      - .name:           'state::ScientificExecutionState'
        .offset:         152
        .size:           536
        .value_kind:     by_value
      - .name:           'ordinal::UInt32'
        .offset:         688
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 692
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_
    .private_segment_fixed_size: 0
    .sgpr_count:     18
    .sgpr_spill_count: 0
    .symbol:         _Z25gpu__checkerboard_commit_16CompilerMetadataI11DynamicSize12DynamicCheckv16CartesianIndicesILi1E5TupleI5OneToI5Int64EEE7NDRangeILi1ES0_10StaticSizeI6_256__ES8_vEE14ROCDeviceArrayI6UInt32Li1ELi1EESG_SE_I21StagedCopyTransactionIS5_13NoMomentDeltaELi1ELi1EESE_I5UInt8Li1ELi1EE24ScientificExecutionStateI20CompiledStateStorageI17CompiledOwnershipILi2ESE_ISL_Li2ELi1EESE_ISF_Li2ELi1EEESM_SE_I6UInt64Li1ELi1EESG_SG_SG_10NamedTupleI36__volume__target___volume__strength_S3_ISE_I7Float32Li1ELi1EESX_EEE23CompiledCartesianDomainI25CartesianDomainDescriptorILi2ESW_S3_I12AxisBoundaryI16PeriodicBoundaryS14_ES15_EE30CompiledCartesianDomainStorageISQ_SG_SQ_SR_EE24ScientificTrackerStorageISE_I5Int32Li1ELi1EES1D_SE_IS5_Li1ELi1EE15NoMomentStorageE22BoundaryMeasureTrackerI17BoundaryEdgeCount23StaticCartesianRelationI11SurfaceRoleLi2ELi4ESW_S3_I6SArrayIS3_ILi2EES1C_Li1ELi2EES1N_S1N_S1N_ES1L_IS3_ILi4EESW_Li1ELi4EES1L_IS1P_6UInt16Li1ELi4EEEESV_I36__volume__target___volume__strength_S3_ISW_SW_EES3_ISF_EESF_.kd
    .uses_dynamic_stack: false
    .vgpr_count:     18
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
