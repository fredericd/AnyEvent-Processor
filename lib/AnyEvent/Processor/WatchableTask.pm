package AnyEvent::Processor::WatchableTask;
#ABSTRACT: Role for tasks which are watchable

use Moose::Role;

requires 'process_message';
requires 'start_message';
requires 'end_message';

1;

=pod

=head1 DESCRIPTION

Defines methods that a watchable task must implement.

=method process_message

=method start_message

=method end_message

=cut
