{{
userdefs_template.spin - defines user platform properties.

For first time use:
1) Copy this file to userdefs.spin in your library directory.
2) Change your personalized userdefs.spin file to meet your needs.

}}

con '' clock settings

    _clkmode    = xtal1 + pll16x
'    _xinfreq    = 6_553_600
    _xinfreq    = 5_000_000

con '' console uart settings

    conRxPin    = 31        '' the RX pin to use for UART console
    conTxPin    = 30        '' the TX pin to use for UART console
    conMode     = 0         '' the mode to use for FullDuplex UART console
    conBaud     = 115200    '' the baud rate to use for UART console
    conWait     = 1         '' seconds to wait after starting UART before output

con '' microSD pin definitions
    'TriBlade2 pins
    spiDO       = 9
    spiClk      = 28
    spiDI       = 8
    spiCS       = 14

pub nopub '' not used

