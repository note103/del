#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

my $fmt = '';

init();

sub init {
    print "f/d/a/q?\n>> ";
    chomp(my $init = <STDIN>);
    
    $fmt = '';
    if ($init eq 'f') {
        $fmt = 'file'
    }
    elsif ($init eq 'd') {
        $fmt = 'dir'
    }
    elsif ($init eq 'a') {
        $fmt = 'other'
    }
    elsif ($init eq 'q') {
        say "Exit.";
        exit;
    }
    else {
        init();
    }

    say "pwd:";
    pwd();

    say 'ls:';
    iter($fmt);

    main($fmt);
}

sub pwd {
    my $pwd = `pwd`;
    say "\t$pwd";
}

sub iter {
    my (@file, @dir, @other) = '';
    my $fmt = shift;
    my $dir = '.';
    my $last_dir = '';

    opendir (my $iter, $dir) or die;
    for (readdir $iter) {
        next if ($_ =~ /^\./);
        if (-f $dir.'/'.$_) {
            push @file, "\tfile: $dir/$_\n";
        } elsif (-d $dir.'/'.$_) {
            push @dir, "\tdir: $dir/$_\n";
            $last_dir = $_;
        } else {
            push @other, "\tother: $dir/$_\n";
        }
    }
    closedir $iter;

    ls($fmt, \@file, \@dir, \@other);
}

sub ls {
    my ($fmt, $file, $dir, $other) = @_;
    if ($fmt eq 'dir') {
        print @$dir;
    }
    elsif ($fmt eq 'file') {
        print @$file;
    }
    else {
        print @$dir;
        print @$file;
        print @$other;
    }
}

sub main {
    my $trash = [];
    say '';
    say "Put the target words.(or [ls/q/quit])";
    chomp(my $get = <STDIN>);

    if ($get =~ /\A(q|quit)\z/) {
        say "Exit.";
        exit;
    }
    elsif ($get =~ /\A\z/) {
        init();
    }
    elsif ($get =~ /\A(ls)\z/) {
        iter($fmt);
        main($fmt);
    }
    elsif ($get =~ /\A(pwd)\z/) {
        pwd();
        main($fmt);
    }
    else {
        my ($first, $other);
        my @other = '';
        if ($get =~ /\A(\S+)(( (\S+))+)/) {
            $first = $1;
            $other = $2;
            @other = split / /, $other;
        }
        elsif ($get =~ /\A(\S+)(\s*)\z/) {
            $first = $1;
        } else {
            die "Can't open target:$!";
        }
        unshift @other, $first;

        my $dir = '.';
        my $search = '';
        opendir (my $iter, $dir) or die;
        my $f = sub {
            $search = shift;
            for my $target (@other) {
                next if ($target eq '');
                if ($search =~ /$target/) {
                    say 'Matched: '.$search;
                    push @$trash, $search;
                }
            }
        };
        for $search (readdir $iter) {
            next if ($search =~ /^\./);
            if ($fmt eq 'file') {
                if (-f $dir.'/'.$search) {
                    $f->($search);
                }
            }
            elsif ($fmt eq 'dir') {
                if (-d $dir.'/'.$search) {
                    $f->($search);
                }
            }
            else {
                if (-e $dir.'/'.$search) {
                    for my $target (@other) {
                        next if ($target eq '');
                        if ($search =~ /$target/) {
                            say 'Matched: '.$search;
                            push @$trash, $search;
                        }
                    }
                }
           }
        }
        closedir $iter;

        if (scalar(@$trash) == 0) {
            say "Not matched: $get\n";
            init();
        } else {
            del($trash, $fmt);
        }
    }
}

sub del {
    my $trash = shift;
    my @trash = @$trash;

    say '';
    print "Delete it OK? [y/N]\n";

    chomp(my $decision = <STDIN>);
    if ($decision =~/(y|yes)/i) {
        my $trash = '$HOME/.tmp_trash/my_trash_box';
        system("if [ ! -e $trash ] ; then mkdir $trash ; fi") == 0 or die "system 'mkdir' failed: $?";
        system("mv @trash $trash") == 0 or die "system 'mv' failed: $?";
        for (@trash) {
            say "Delete successful. $_\t-> $trash";
        }
    } else {
        say "Nothing changes.";
    }
    say '';
    init();
}
