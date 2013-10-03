use strict;
use warnings;

use Test::More;

use Test::Requires (
    'MaxMind::DB::Reader' => 0.040000,
);

use MaxMind::DB::Writer::Tree::InMemory;
use MaxMind::DB::Writer::Tree::File;

use File::Temp qw( tempdir );
use Net::Works::Network;

my $tempdir = tempdir( CLEANUP => 1 );

{
    my $filename = _write_tree();

    my $reader = MaxMind::DB::Reader->new( file => $filename );

    for my $address (qw( 0.0.0.0 0.0.0.1 0.0.0.255 )) {
        is_deeply(
            $reader->record_for_address($address),
            {
                ip => '0.0.0.0',
            },
            "got expected data for $address"
        );
    }
}

done_testing();

sub _write_tree {
    my $tree = MaxMind::DB::Writer::Tree::InMemory->new( ip_version => 4 );

    my $subnet = Net::Works::Network->new_from_string(
        string  => '0.0.0.0/24',
        version => 4,
    );

    $tree->insert_subnet(
        $subnet,
        {
            ip => '0.0.0.0'
        },
    );

    my $writer = MaxMind::DB::Writer::Tree::File->new(
        tree          => $tree,
        record_size   => 24,
        database_type => 'Test',
        languages     => [ 'en', 'zh' ],
        description   => {
            en => 'Test Database',
            zh => 'Test Database Chinese',
        },
        ip_version            => 4,
        map_key_type_callback => sub { 'utf8_string' },
    );

    my $filename = $tempdir . "/Test-0-network.mmdb";
    open my $fh, '>', $filename;

    $writer->write_tree($fh);

    return $filename;
}
