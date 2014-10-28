package AnyEvent::Processor;
#ABSTRACT: Base class to define an event-driven (AnyEvent) task that could periodically be interrupted by a watcher

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

An AnyEvent::Processor::Watcher.

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

Something to do at beginning of the process.

=cut
sub start_process { }


=method start_message

Something to say about the process. Called by default watcher when verbose mode
is enabled. By default, just send to STDOUT 'Start process...'. Your class can
display another message, or do something else, like sending an email, or a
notification to a monitoring system like Nagios.

=cut
sub start_message {
    print "Start process...\n";
}


=method process

Process something and increment L<count>. This method has to be surclassed by
you class if you want to do someting else than incrementing the C<count>
attribute.

=cut
sub process {
    my $self = shift;
    $self->count( $self->count + 1 );
    return 1;
}


=method process_message

Say something about the process. Called by default watcher (verbose mode) each
1s. By default, just display the C<count> value. Your processor can display
something else than just the number of processing clusters already processed.
If your processor monitor the temperature of your fridge, you can display it...

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

=head1 DESCRIPTION

A processor task based on this class process anything that can be divided into
processing clusters. Each cluster is processed one by one by calling the
process() method. A count is incremented at the end of each cluster. By
default, a L<AnyEvent::Processor::Watcher> is associated with the class,
interrupting the processing each second for calling C<process_message>. 

=head1 SYNOPSIS

  package FridgeMonitoring;
  
  use Moose;
  extends 'AnyEvent::Processor';
  use TemperatureSensor;
  
  has sensors => (is => 'rw', isa => 'ArrayRef[TemperatureSensor]');
  has min => (is => 'rw', isa => 'Int', default => '10');
  has max => (is => 'rw', isa => 'Int', default => '20');
  
  
  sub process {
      my $self = shift;
  
      my @failed;
      for my $sensor ( @{$self->sensors} ) {
          next if $self->sensor->temperature >= $self->min &&
                  $self->sensor->temperature <= $self->max;
          push @failed, $sensor;
      }
      if ( @failed ) {
          # Send an email to someone with the list of failed fridges
      }
  }
  
  sub process_message {
      my $self = shift;
      say "[", $self->count, "] Fridges testing";
  }


package Main;

use FridgeMonitoring;

my $processor = FridgeMonitoring->new(
    sensors => # Get a list of fridge sensors from somewhere
    min => 0,
    max => 40,
);
$processor->run();


=head1 SEE ALSO

=for :list
* L<AnyEvent::Processor::Converion
* L<AnyEvent::Processor::Watcher


