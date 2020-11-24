package CD::Music::mysql;
use strict;
use base qw(CD::mysql);

__PACKAGE__->construct;
__PACKAGE__->set_up_table("music");

sub construct {
    my $class = shift;
    $class->db_Main->do(<<SQL);
CREATE TABLE music (
    id int unsigned NOT NULL PRIMARY KEY auto_increment,
    artist varchar(64),
    title  varchar(128),
    label  varchar(128)
)
SQL
    ;
    END { $class->destruct; }
}

sub destruct {
    shift->db_Main->do('DROP TABLE music');
}

package CD::Music::SQLite;
use base qw(CD::SQLite);

__PACKAGE__->construct;
__PACKAGE__->set_up_table("music");

sub construct {
    my $class = shift;
    $class->db_Main->do(<<SQL);
CREATE TABLE music (
    id integer PRIMARY KEY,
    artist varchar(64),
    title  varchar(128),
    label  varchar(128)
)
SQL
    ;
    END { $class->destruct; }
}

sub destruct {
    shift->db_Main->do('DROP TABLE music');
}


1;
