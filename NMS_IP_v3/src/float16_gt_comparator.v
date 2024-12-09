module float16_gt_comparator (
    input  [15:0] a,
    input  [15:0] b,
    output        a_gt_b
);
    // Extract sign, exponent, and mantissa
    wire sign_a = a[15];
    wire sign_b = b[15];
    wire [4:0] exp_a = a[14:10];
    wire [4:0] exp_b = b[14:10];
    wire [9:0] frac_a = a[9:0];
    wire [9:0] frac_b = b[9:0];

    assign a_gt_b = (sign_a == 1'b0 && sign_b == 1'b1) ? 1 : // Positive is greater than negative
                    (sign_a == 1'b1 && sign_b == 1'b0) ? 0 : // Negative is less than positive
                    (sign_a == 1'b0 && sign_b == 1'b0) ? // Both positive
                        (exp_a > exp_b) ? 1 :
                        (exp_a < exp_b) ? 0 :
                        (frac_a > frac_b) ? 1 : 0 :
                    (sign_a == 1'b1 && sign_b == 1'b1) ? // Both negative
                        (exp_a < exp_b) ? 1 :
                        (exp_a > exp_b) ? 0 :
                        (frac_a < frac_b) ? 1 : 0 : 0;
endmodule

