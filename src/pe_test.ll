; ModuleID = 'pe_test'
source_filename = "pe_test"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @r(i32 %x_1030) {
r_start:
  br label %r

r:                                                ; preds = %r_start
  %0 = icmp eq i32 %x_1030, 0
  br i1 %0, label %expr_true, label %expr_false

expr_false:                                       ; preds = %r
  ret i32 20

expr_true:                                        ; preds = %r
  ret i32 16
}

define i32 @r_no(i32 %x_1040) {
r_no_start:
  br label %r_no

r_no:                                             ; preds = %r_no_start
  %0 = icmp eq i32 %x_1040, 0
  br i1 %0, label %expr_true, label %expr_false

expr_false:                                       ; preds = %r_no
  br label %if_join

expr_true:                                        ; preds = %r_no
  br label %if_join

if_join:                                          ; preds = %expr_true, %expr_false
  %v = phi i32 [ 9, %expr_true ], [ 13, %expr_false ]
  %1 = add nsw i32 7, %v
  ret i32 %1
}
