package AnyEvent::Processor::Conversion;
# ABSTRACT: Base class for conversion type subclasses

use Moose;

extends 'AnyEvent::Processor';


=attr reader

The L<MooseX::RW::Reader> from which reading something.

=cut
has reader => (
    is => 'rw', 
    does => 'MooseX::RW::Reader',
);

=attr writer

The L<Moose::RW::Writer> in which writing something.

=cut
has writer => ( 
    is => 'rw',
    does => 'MooseX::RW::Writer',
);

=attr converter

Convert something read from the reader into something to write to the writer.

=cut
has converter => ( is => 'rw', does => 'AnyEvent::FP:Converter' );


sub run  {
    my $self = shift;
    $self->writer->begin();
    $self->SUPER::run();
    $self->writer->end();
};


sub process {
    my $self = shift;
    my $record = $self->reader->read();
    if ( $record ) {
        $self->SUPER::process();
        my $converter = $self->converter;
        my $converted_record = 
            $converter ? $converter->convert( $record ) : $record;
        unless ( $converted_record ) {
            # Conversion échouée mais il reste des enregistrements
            # print "NOTICE NON CONVERTIE #", $self->count(), "\n";
            return 1;
        }
        $self->writer->write( $converted_record );
        return 1;
    }
    return 0;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

