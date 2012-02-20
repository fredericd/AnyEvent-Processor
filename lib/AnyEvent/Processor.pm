package AnyEvent::Processor;
#ABSTRACT: AnyEvent::Processor - Base class for processing something

use Moose;

use 5.010;
use AnyEvent;
use AnyEvent::Processor::Watcher;

with 'AnyEvent::Processor::WatchableTask';


=attr verbose

Verbose mode. In this mode an AnyEvent::Processor::Watcher is automatically
created, with a 1s timeout, and action directly sent to this class. You can
create your own watcher subclassing AnyEvent::Processor::Watcher.

=cut
has verbose => ( is => 'rw', isa => 'Int' );

=attr watcher

A AnyEvent::Processor::Watcher.

=cut
has watcher => ( 
    is => 'rw', 
    isa => 'AnyEvent::Processor::Watcher',
);

=attr count

Number of items which have been processed.

=cut
has count => ( is => 'rw', isa => 'Int', default => 0 );

=attr blocking

Is it a blocking task (not a task). False by default.

=cut
has blocking => ( is => 'rw', isa => 'Bool', default => 0 );


=method run

Run the process.

=cut
sub run {
    my $self = shift;
    if ( $self->blocking) {
        $self->run_blocking();
    }
    else {
        $self->run_task();
    }
}


sub run_blocking {
    my $self = shift;
    while ( $self->process() ) {
        ;
    }
}


sub run_task {
    my $self = shift;

    $self->start_process();

    if ( $self->verbose ) {
        $self->watcher( AnyEvent::Processor::Watcher->new(
            delay => 1, action => $self ) ) unless $self->watcher;
        $self->watcher->start();
    }

    my $end_run = AnyEvent->condvar;
    my $idle = AnyEvent->idle(
        cb => sub {
            unless ( $self->process() ) {
                $self->end_process();
                $self->watcher->stop() if $self->watcher;
                $end_run->send;
            }
        }
    );
    $end_run->recv;
}


=method start_process

Something to do at begining of the process.

=cut
sub start_process { }


=method start_message

Something to say about the process. Called by default watcher when verbose mode enabled.

=cut
sub start_message {
    print "Start process...\n";
}


=method process

Process something and increment L<count>.

=cut
sub process {
    my $self = shift;
    $self->count( $self->count + 1 );
    return 1;
}


=method process_message

Say something about the process. Called by default watcher (verbose mode) each 1s.

=cut
sub process_message {
    my $self = shift;
    print sprintf("  %#6d", $self->count), "\n";    
}


=method end_process

Do something at the end of the process.

=cut
sub end_process { return 0; }


=method end_message

Say something at the end of the process. Called by default watcher.

=cut
sub end_message {
    my $self = shift; 
    print "Number of items processed: ", $self->count, "\n";
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;

