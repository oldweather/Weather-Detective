# Run all the WD data conversion scripts in the correct order
cd get_ship_names
R --no-save < names.R # May need to update cannonical names.txt
cd ../make_cannonical
./make_cannonical.perl > cannonical.out
cd ../check_dates
R --no-save < dates.R
cd ../interpolate_positions # Might want to save old positions for comparisons
R --no-save < interpolate_positions.R
cd ../convert_units/
./convert_units.perl
cd ../to_imma
./to_imma.perl

