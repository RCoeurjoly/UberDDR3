set PHASER_BYTE_LANE_ORACLE_PROBES {
    {capture_clk {{top_i/clk50} {clk50} {top_i/u_clk50}} 1}
    {phaser_pll_locked {{top_i/*phaser*pll*locked*} {top_i/*phaser*pll*LOCKED*} {top_i/*pll_locked*} {top_i/*pll*LOCKED*}} 1}
    {phaser_ref_locked {{top_i/*phaser*ref*locked*} {top_i/*phaser_ref*locked*} {top_i/*ref*locked*}} 1}
    {in_phase_locked {{top_i/*in*phase*locked*} {top_i/*phase*locked*} {top_i/*PHASER_IN*PHASE*}} 1}
    {phyctl_ready {{top_i/*phyctl*ready*} {top_i/*PHYCTLREADY*} {top_i/*phctl*ready*}} 1}
    {phaser_ref_pwrdwn {{top_i/*phaser*pwrdwn*} {top_i/*PHASER*PWRDWN*} {top_i/*ref*pwrdwn*}} 1}
    {phaser_ref_reset {{top_i/*phaser*reset*} {top_i/*PHASER*RESET*} {top_i/*ref*reset*}} 1}
    {phyctl_reset {{top_i/*phyctl*reset*} {top_i/*phy*control*reset*} {top_i/*PHYCTL*RESET*}} 1}
    {phyctl_readcalibenable {{top_i/*readcalib*enable*} {top_i/*PHY_CTL*READ*} {top_i/*READCALIB*}} 1}
    {phyctl_writecalibenable {{top_i/*writecalib*enable*} {top_i/*PHY_CTL*WRITE*} {top_i/*WRITECALIB*}} 1}
    {phyctlwrenable {{top_i/*phyctl*wrenable*} {top_i/*PHYCTLWRENABLE*} {top_i/*PHYCTL*WD*}} 1}
    {phyctlwd {{top_i/*phyctl*wd*} {top_i/*PHYCTLWD*} {top_i/*phyctl_wd*}} 32}
    {lane_reset {{top_i/*lane*reset*} {top_i/*LANE*RESET*} {top_i/*INPHY*RST*}} 1}
    {rstdqsfind {{top_i/*rstdqs*} {top_i/*RSTDQSFIND*} {top_i/*RSTDQS*}} 1}
    {sync_enable {{top_i/*sync*enable*} {top_i/*SYNCIN*} {top_i/*syncin*}} 1}
    {dqs_found {{top_i/*dqs*found*} {top_i/*PHASER_IN*DQS*FOUND*} {top_i/*DQSFOUND*}} 1}
    {dqs_out_of_range {{top_i/*dqs*out*range*} {top_i/*PHASER_IN*OUT*RANGE*} {top_i/*dqs_out_of_range*}} 1}
    {in_wrenable {{top_i/*in*wrenable*} {top_i/*PHY_IN*WRENABLE*} {top_i/*in_wrenable*}} 1}
    {out_rd_enable {{top_i/*out*rd*enable*} {top_i/*PHASER_OUT*RD*ENABLE*} {top_i/*out_rd_enable*}} 1}
}
