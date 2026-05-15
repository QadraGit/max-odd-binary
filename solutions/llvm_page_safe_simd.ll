declare i32 @llvm.ctpop.i32(i32)
declare i32 @llvm.cttz.i32(i32, i1 immarg)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define ptr @maximum_odd_binary(ptr nocapture %s) #0 {
entry:
  %addr_int = ptrtoint ptr %s to i64
  %page_offset = and i64 %addr_int, 4095
  %is_danger_zone = icmp ugt i64 %page_offset, 4032
  br i1 %is_danger_zone, label %safe_scalar_prelude, label %chunk_loop

safe_scalar_prelude:
  %i.al = phi i64 [ 0, %entry ], [ %i.al.next, %safe_scalar_cont ]
  %onesA.al = phi i32 [ 0, %entry ], [ %onesA.al.next, %safe_scalar_cont ]
  
  %ptr.al = getelementptr inbounds i8, ptr %s, i64 %i.al
  %c.al = load i8, ptr %ptr.al, align 1
  %is_zero.al = icmp eq i8 %c.al, 0
  br i1 %is_zero.al, label %alloc_phase_early, label %safe_scalar_cont

safe_scalar_cont:
  %is_one.al = icmp eq i8 %c.al, 49
  %ones.ext.al = zext i1 %is_one.al to i32
  %onesA.al.next = add i32 %onesA.al, %ones.ext.al
  %i.al.next = add i64 %i.al, 1
  
  %addr_cur = add i64 %addr_int, %i.al.next
  %is_aligned_cur = and i64 %addr_cur, 4095
  %cmp_aligned = icmp eq i64 %is_aligned_cur, 0
  br i1 %cmp_aligned, label %chunk_loop, label %safe_scalar_prelude

chunk_loop:
  %i = phi i64 [ 0, %entry ], [ %i.al.next, %safe_scalar_cont ], [ %i.next, %process_chunk ]
  %onesA = phi i32 [ 0, %entry ], [ %onesA.al.next, %safe_scalar_cont ], [ %onesA.next, %process_chunk ]
  %onesB = phi i32 [ 0, %entry ], [ 0, %safe_scalar_cont ], [ %onesB.next, %process_chunk ]

  %ptrA = getelementptr inbounds i8, ptr %s, i64 %i
  %chunkA = load <32 x i8>, ptr %ptrA, align 1
  %cmp_zeroA = icmp eq <32 x i8> %chunkA, zeroinitializer
  %zero_maskA = bitcast <32 x i1> %cmp_zeroA to i32
  %has_zeroA = icmp ne i32 %zero_maskA, 0
  br i1 %has_zeroA, label %found_zeroA, label %check_B

check_B:
  %i_plus_32 = add i64 %i, 32
  %ptrB = getelementptr inbounds i8, ptr %s, i64 %i_plus_32
  %chunkB = load <32 x i8>, ptr %ptrB, align 1
  %cmp_zeroB = icmp eq <32 x i8> %chunkB, zeroinitializer
  %zero_maskB = bitcast <32 x i1> %cmp_zeroB to i32
  %has_zeroB = icmp ne i32 %zero_maskB, 0
  br i1 %has_zeroB, label %found_zeroB, label %process_chunk

process_chunk:
  %cmp_onesA = icmp eq <32 x i8> %chunkA, <i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49>
  %ones_maskA = bitcast <32 x i1> %cmp_onesA to i32
  %popcntA = tail call i32 @llvm.ctpop.i32(i32 %ones_maskA)
  %onesA.next = add i32 %onesA, %popcntA

  %cmp_onesB = icmp eq <32 x i8> %chunkB, <i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49>
  %ones_maskB = bitcast <32 x i1> %cmp_onesB to i32
  %popcntB = tail call i32 @llvm.ctpop.i32(i32 %ones_maskB)
  %onesB.next = add i32 %onesB, %popcntB

  %i.next = add i64 %i, 64
  br label %chunk_loop

found_zeroA:
  %zero_bit_idxA = tail call i32 @llvm.cttz.i32(i32 %zero_maskA, i1 true)
  %zero_bit_idx_64A = zext i32 %zero_bit_idxA to i64
  %lenA = add i64 %i, %zero_bit_idx_64A

  %cmp_onesA_final = icmp eq <32 x i8> %chunkA, <i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49>
  %ones_maskA_final = bitcast <32 x i1> %cmp_onesA_final to i32
  %valid_mask_shlA = shl i32 1, %zero_bit_idxA
  %valid_maskA = sub i32 %valid_mask_shlA, 1
  %masked_ones_finalA = and i32 %ones_maskA_final, %valid_maskA
  %popcnt_finalA = tail call i32 @llvm.ctpop.i32(i32 %masked_ones_finalA)
  %onesA.final = add i32 %onesA, %popcnt_finalA
  br label %alloc_phase

found_zeroB:
  %zero_bit_idxB = tail call i32 @llvm.cttz.i32(i32 %zero_maskB, i1 true)
  %zero_bit_idx_64B = zext i32 %zero_bit_idxB to i64
  %len_baseB = add i64 %i, 32
  %lenB = add i64 %len_baseB, %zero_bit_idx_64B

  %cmp_onesA_full = icmp eq <32 x i8> %chunkA, <i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49>
  %ones_maskA_full = bitcast <32 x i1> %cmp_onesA_full to i32
  %popcntA_full = tail call i32 @llvm.ctpop.i32(i32 %ones_maskA_full)
  %onesA.finalB = add i32 %onesA, %popcntA_full

  %cmp_onesB_final = icmp eq <32 x i8> %chunkB, <i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49, i8 49>
  %ones_maskB_final = bitcast <32 x i1> %cmp_onesB_final to i32
  %valid_mask_shlB = shl i32 1, %zero_bit_idxB
  %valid_maskB = sub i32 %valid_mask_shlB, 1
  %masked_ones_finalB = and i32 %ones_maskB_final, %valid_maskB
  %popcnt_finalB = tail call i32 @llvm.ctpop.i32(i32 %masked_ones_finalB)
  %onesB.finalB = add i32 %onesB, %popcnt_finalB
  br label %alloc_phase

alloc_phase_early:
  %len_early = phi i64 [ %i.al, %safe_scalar_prelude ]
  %ones_early_32 = phi i32 [ %onesA.al, %safe_scalar_prelude ]
  br label %alloc_phase

alloc_phase:
  %len_final = phi i64 [ %lenA, %found_zeroA ], [ %lenB, %found_zeroB ], [ %len_early, %alloc_phase_early ]
  %ones_resA = phi i32 [ %onesA.final, %found_zeroA ], [ %onesA.finalB, %found_zeroB ], [ %ones_early_32, %alloc_phase_early ]
  %ones_resB = phi i32 [ %onesB, %found_zeroA ], [ %onesB.finalB, %found_zeroB ], [ 0, %alloc_phase_early ]
  %ones_total_32 = add i32 %ones_resA, %ones_resB
  %ones_total = zext i32 %ones_total_32 to i64

  %ones_minus_1 = sub i64 %ones_total, 1
  tail call void @llvm.memset.p0.i64(ptr %s, i8 49, i64 %ones_minus_1, i1 false)
  
  %s_offset = getelementptr inbounds i8, ptr %s, i64 %ones_minus_1
  %len_minus_ones = sub i64 %len_final, %ones_total
  tail call void @llvm.memset.p0.i64(ptr %s_offset, i8 48, i64 %len_minus_ones, i1 false)
  
  %len_minus_1 = sub i64 %len_final, 1
  %s_last = getelementptr inbounds i8, ptr %s, i64 %len_minus_1
  store i8 49, ptr %s_last, align 1
  
  ret ptr %s
}

attributes #0 = { "no-builtin-memset" }
