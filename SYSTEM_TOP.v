`timescale 1fs/1fs

module SYSTEM_TOP(

    );

    wire        DU_RU_txp;
    wire        DU_RU_txn;
    wire        RU_DU_rxp;
    wire        RU_DU_rxn;

    wire        RU1_RU2_txp;
    wire        RU1_RU2_txn;
    wire        RU2_RU1_rxp;
    wire        RU2_RU1_rxn;


    wire        rx_gt_locked_led;
    wire        rx_block_lock_led;

    DU_TOP i_du_top
    (
        .gt_rxp_in         (RU_DU_rxp),
        .gt_rxn_in         (RU_DU_rxn),
        .gt_txp_out        (DU_RU_txp),
        .gt_txn_out        (DU_RU_txn),
        .rx_gt_locked_led  (rx_gt_locked_led),
        .rx_block_lock_led (rx_block_lock_led)
    );

    RU_TOP i_ru_1
    (
        .gt0_rxp(DU_RU_txp),
        .gt0_rxn(DU_RU_txn),
        .gt0_txp(RU_DU_rxp),
        .gt0_txn(RU_DU_rxn),
        .gt1_rxp(RU2_RU1_rxp),
        .gt1_rxn(RU2_RU1_rxn),
        .gt1_txp(RU1_RU2_txp),
        .gt1_txn(RU1_RU2_txn)

    );

    RU_TOP i_ru_2
    (
        .gt0_rxp(RU1_RU2_txp),
        .gt0_rxn(RU1_RU2_txn),
        .gt0_txp(RU2_RU1_rxp),
        .gt0_txn(RU2_RU1_rxn),
        .gt1_rxp(1'b0),
        .gt1_rxn(1'b1),
        .gt1_txp(),
        .gt1_txn()

    );

endmodule
