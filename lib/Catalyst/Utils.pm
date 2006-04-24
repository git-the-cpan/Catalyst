package Catalyst::Utils;

use strict;
use Catalyst::Exception;
use File::Spec;
use HTTP::Request;
use Path::Class;
use URI;

=head1 NAME

Catalyst::Utils - The Catalyst Utils

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

=head1 METHODS

=head2 appprefix($class)

	MyApp::Foo becomes myapp_foo

=cut

sub appprefix {
    my $class = shift;
    $class =~ s/\:\:/_/g;
    $class = lc($class);
    return $class;
}

=head2 class2appclass($class);

    MyApp::C::Foo::Bar becomes MyApp
    My::App::C::Foo::Bar becomes My::App

=cut

sub class2appclass {
    my $class = shift || '';
    my $appname = '';
    if ( $class =~ /^(.*)::([MVC]|Model|View|Controller)?::.*$/ ) {
        $appname = $1;
    }
    return $appname;
}

=head2 class2classprefix($class);

    MyApp::C::Foo::Bar becomes MyApp::C
    My::App::C::Foo::Bar becomes My::App::C

=cut

sub class2classprefix {
    my $class = shift || '';
    my $prefix;
    if ( $class =~ /^(.*::[MVC]|Model|View|Controller)?::.*$/ ) {
        $prefix = $1;
    }
    return $prefix;
}

=head2 class2classsuffix($class);

    MyApp::C::Foo::Bar becomes C::Foo::Bar

=cut

sub class2classsuffix {
    my $class = shift || '';
    my $prefix = class2appclass($class) || '';
    $class =~ s/$prefix\:\://;
    return $class;
}

=head2 class2env($class);

Returns the environment name for class.

    MyApp becomes MYAPP
    My::App becomes MY_APP

=cut

sub class2env {
    my $class = shift || '';
    $class =~ s/\:\:/_/g;
    return uc($class);
}

=head2 class2prefix( $class, $case );

Returns the uri prefix for a class. If case is false the prefix is converted to lowercase.

    My::App::C::Foo::Bar becomes foo/bar

=cut

sub class2prefix {
    my $class = shift || '';
    my $case  = shift || 0;
    my $prefix;
    if ( $class =~ /^.*::([MVC]|Model|View|Controller)?::(.*)$/ ) {
        $prefix = $case ? $2 : lc $2;
        $prefix =~ s/\:\:/\//g;
    }
    return $prefix;
}

=head2 class2tempdir( $class [, $create ] );

Returns a tempdir for a class. If create is true it will try to create the path.

    My::App becomes /tmp/my/app
    My::App::C::Foo::Bar becomes /tmp/my/app/c/foo/bar

=cut

sub class2tempdir {
    my $class  = shift || '';
    my $create = shift || 0;
    my @parts = split '::', lc $class;

    my $tmpdir = dir( File::Spec->tmpdir, @parts )->cleanup;

    if ( $create && !-e $tmpdir ) {

        eval { $tmpdir->mkpath };

        if ($@) {
            Catalyst::Exception->throw(
                message => qq/Couldn't create tmpdir '$tmpdir', "$@"/ );
        }
    }

    return $tmpdir->stringify;
}

=head2 controller2action( $class, $method )

Returns the action class for given controller class and method.

    MyApp::Controller::Foo, bar becomes MyApp::Action::Foo::bar

=cut

sub controller2action {
    my ( $class, $method ) = @_;
    if ( $class =~ /::(?:C|Controller)::/ ) {
        my $appclass = class2appclass($class);
        my $suffix   = class2classsuffix($class);
        $suffix =~ s/^.*:://;
        return "$appclass\::Action\::$suffix\::$method";
    }
    else { return "$class\::Action\::$method" }
}

=head2 home($class)

Returns home directory for given class.

=cut

sub home {
    my $name = shift;
    $name =~ s/\:\:/\//g;
    my $home = 0;
    if ( my $path = $INC{"$name.pm"} ) {
        $home = file($path)->absolute->dir;
        $name =~ /(\w+)$/;
        my $append = $1;
        my $subdir = dir($home)->subdir($append);
        for ( split '/', $name ) { $home = dir($home)->parent }
        if ( $home =~ /blib$/ ) { $home = dir($home)->parent }
        elsif (!-f file( $home, 'Makefile.PL' )
            && !-f file( $home, 'Build.PL' ) )
        {
            $home = $subdir;
        }

        # clean up relative path:
        # MyApp/script/.. -> MyApp
        my ($lastdir) = $home->dir_list( -1, 1 );
        if ( $lastdir eq '..' ) {
            $home = dir($home)->parent->parent;
        }
    }
    return $home;
}

=head2 prefix($class, $name);

Returns a prefixed action.

    MyApp::C::Foo::Bar, yada becomes foo/bar/yada

=cut

sub prefix {
    my ( $class, $name ) = @_;
    my $prefix = &class2prefix($class);
    $name = "$prefix/$name" if $prefix;
    return $name;
}

=head2 request($uri)

Returns an L<HTTP::Request> object for a uri.

=cut

sub request {
    my $request = shift;
    unless ( ref $request ) {
        if ( $request =~ m/^http/i ) {
            $request = URI->new($request)->canonical;
        }
        else {
            $request = URI->new( 'http://localhost' . $request )->canonical;
        }
    }
    unless ( ref $request eq 'HTTP::Request' ) {
        $request = HTTP::Request->new( 'GET', $request );
    }
    return $request;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
