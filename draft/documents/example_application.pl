

# SIMPLE SWITCH OVER FROM DC1 TO DC2

$dc1->take_offline;
$dc2->take_online;


# Data Centre methods
#
sub take_dc_offline {
    my ($dc) = @_;

    $dc->app->stop_and_wait_until_status_is('STOPPED');
    $dc->db->offline_and_wait_until_status_is('OFFLINE');
}

sub take_dc_online {
    my ($dc) = @_;

    $dc->db->online_and_wait_until_status_is('ONLINE');
    $dc->app->start_and_wait_until_status_is('RUNNING');
}









