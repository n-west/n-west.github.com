#!/bin/bash
# Version 0.1
# run ./grc_to_37 <appname>.grc
# this will create a backup copy and attempt to convert the api calls to 3.7
GRCFILE=$1
cp $GRCFILE $GRCFILE.pre3.7upgrade_backup # I refuse to take responsibility for breaking your flowgraphs
# set up a list of partial regexps to change modules
list_of_block_changes=(
"gr_keep_one_in_n/blocks_keep_one_in_n"
"gr_complex_to_real/blocks_complex_to_real"
"gr_complex_to_mag_squared/blocks_complex_to_mag_squared"
"gr_probe_avg_mag_sqrd_x/analog_probe_avg_mag_sqrd_x"
"gr_float_to_short/blocks_float_to_short"
"gr_add_xx/blocks_add_xx"
"gr_multiply_const_vxx/blocks_multiply_const_vxx"
"gr_fft_filter_xxx/fft_filter_xxx"
"gr_feedforward_agc_cc/analog_feedforward_agc_cc"
"gr_freq_xlating_fir_filter_xxx/freq_xlating_fir_filter_xxx"
"gr_fractional_interpolator_xx/fractional_interpolator_xx"
"gr_wavfile_sink/blocks_wavfile_sink"
"gr_file_sink/blocks_file_sink"
"gr_quadrature_demod_cf/analog_quadrature_demod_cf"
"blks2_fm_deemph/analog_fm_deemph"
)

for block in "${list_of_block_changes[@]}"
do
    sed --in-place "/<key/s/$block/g" $GRCFILE
    # only replace the keys lines because otherwise
    # block ids can get clobbered if there are 2 of the same block
    # one old, and one new that both use grc generated ids
done

