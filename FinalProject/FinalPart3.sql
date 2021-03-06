-- AddArtist Procedure
drop procedure if exists medialibrary.addartist;
delimiter \\
create procedure medialibrary.addartist (aname varchar(50))
begin
	declare newartistid int;
    
    if not exists
    (
		select * 
        from artist
        where artistname = aname
    )
    then
		set newartistid = (select max(artistid) + 1 from medialibrary.artist);
		insert into medialibrary.artist (artistid, artistname) 
        values (newartistid, aname);
        
    end if;
	
end \\
delimiter ;

call medialibrary.addartist('Avicici');
select * from artist;

-- AddAlbum Procedure
drop procedure if exists medialibrary.addalbum; 
delimiter \\
create procedure medialibrary.addalbum (altitle varchar(50), algenre varchar(20), alyear int(11), allabel varchar(30), almediatype varchar(30), aname varchar(50))
begin 
    declare newartistid int;
    
    -- Add the artist if they do not already exist in the artist table
    if not exists 
    (
		select * from artist where artistname = aname 
    )
    then 
		call medialibrary.addartist(aname);
	end if;

	-- Set the newartist id to the one equal tot
	set newartistid = 
	(
		select art.artistid 
		from artist art
		where art.artistname = aname
	);
    
    -- Check if the album does not exist using the album and artist. If the album already exists, we update the album 
    -- If it does not exist, add the album.
    if not exists
    (
		select * 
		from 
			medialibrary.album al
            join artist a 
            on al.artistid = a.artistid
		where 
			al.albumtitle = altitle and
			a.artistname = aname
	)
    then 
		insert into medialibrary.album (albumtitle, genre, year, label, mediatype, artistid)
        values (altitle, algenre, alyear, allabel, almediatype, newartistid);
	else
		update album, artist
        set genre = algenre, year = alyear, label = allabel, mediatype = almediatype
        where album.albumtitle = altitle and artist.artistname = aname;
	end if;
		
        
end \\
delimiter ;

call medialibrary.addalbum('Bars', 'pink Rock', 2017, 'Undergrond Music', 'Vinyl', 'sean');
call medialibrary.addalbum('Baps', 'pink Rock', 2017, 'Undergrond Music', 'CD', 'rhett');
select * from album;

-- addtrack procedure
drop procedure if exists medialibrary.addtrack; 
delimiter \\
create procedure medialibrary.addtrack (ttracktitle varchar(50), ttracknumber int(11), talbumtitle varchar(50), tprimaryartist varchar(50), tfeaturedartist varchar(50))
begin 
	declare newalbumid int;
    declare newartistid int;
    declare newtrackid int;
    declare newfeaturedartistid int;
    
    set newalbumid = (select albumid from album a where a.albumtitle = talbumtitle limit 1);
    
	-- If a featured artist is passed, add them to the artist table if they have not already been added
	if (tfeaturedartist != '')
    then 
		call medialibrary.addartist(tfeaturedartist);
    end if;
    
    -- Add the primary artist to the artist table if they are not already in there
    if not exists ( select * from artist where tprimaryartist = artist.artistname)
    then 
		call medialibrary.addartist(tprimaryartist);
	end if;
    
    -- Check if a track exists. If it does not, add it to the table. Don't add it again if it already exists
    if not exists ( select * from tracks t join album a on t.albumid = a.albumid where t.title = ttracktitle and t.number = ttracknumber and a.albumtitle = talbumtitle)
    then
		insert into medialibrary.tracks (title, number, albumid)
        values (ttracktitle, ttracknumber, newalbumid);
    end if;
    
    -- Check if the track has a relationship to the primary artist int he artisttrack table. If there does not exist one, add it. If it does, do nothing.
    -- These two variables just help us save space on the select statement in the if condition
	set newartistid = (select artistid from artist a where a.artistname = tprimaryartist);
    set newtrackid = (select trackid from tracks t where t.title = ttracktitle);
    if not exists (select * from artisttrack at where at.trackid = newtrackid and at.artistid = newartistid)
		then
		insert into artisttrack 
        values (newartistid, newtrackid, 'y');
	end if;
    
    -- Check if the track has a relationship to the featured artist int he artisttrack table. If there does not exist one, add it. If it does, do nothing.
	set newfeaturedartistid = (select artistid from artist a where a.artistname = tfeaturedartist);
    if not exists (select * from artisttrack at where at.trackid = newtrackid and at.artistid = newartistid)
		then
		insert into artisttrack 
        values (newartistid, newtrackid, 'n');
	end if;
end \\
delimiter ;

call medialibrary.addtrack ('My Own Song', 1, 'emotions', 'AJ', 'CJ');

select * from tracks;
select * from artist;
select * from artisttrack;

-- addplaylist procedure
drop procedure if exists addplaylist;
delimiter \\
create procedure medialibrary.addplaylist (ptrack varchar(50), plist varchar(100))
begin 
	declare counter int;
    declare lastvalue varchar(100);
    declare priorvalue varchar(100);
    declare newplaylistid int;
    declare newtrackid int;
    
    set priorvalue = '';
    set lastvalue = trim(substring_index(plist, ',', -1));
    
    set counter = 1;
    
    -- Iterate through all values in playlist passed, seperated by commas, and add each playlist that does not yet
    -- exist in the playlist table to the playlist table. 
    while lastvalue != priorvalue
    do 
		set priorvalue = trim(substring_index(substring_index(plist, ',', counter), ',', -1));
			
		-- The actuall adding of the playlists to the playlist table
        if not exists(select * from playlists p where p.playlist = priorvalue)
        then
			insert into playlists (playlist)
            values (priorvalue);
		end if;
        
        -- Connect track to playlist in the bridge table, 'trackplaylists'
        set newplaylistid = (select playlistid from playlists p where priorvalue = playlist);
        set newtrackid = (select trackid from tracks t where t.title = ptrack);
        if not exists (select * from trackplaylists tp where tp.trackid = newtrackid and tp.playlistid = newplaylistid)
		then
			insert into trackplaylists values (newtrackid, newplaylistid); 
		end if;
        
        set counter = counter + 1;
	end while;

end \\
delimiter ;

call medialibrary.addplaylist ('Number 1', 'P1, jammy jamers, p9 , p4, 5, g, a, h, e, s, z, P3');
select * from trackplaylists;

-- addtags procedure 
drop procedure if exists addtags;
delimiter \\
create procedure medialibrary.addtags (ttrack varchar(50), tlist varchar(100))
begin 
	declare counter int;
    declare lastvalue varchar(100);
    declare priorvalue varchar(100);
    declare newtagid int;
    declare newtrackid int;
    
    set priorvalue = '';
    set lastvalue = trim(substring_index(tlist, ',', -1));
    
    set counter = 1;
    
    while lastvalue != priorvalue
    do
		set priorvalue = trim(substring_index(substring_index(tlist, ',', counter), ',', -1));
        
        if not exists (select * from tags t where t.tag = priorvalue)
        then 
			insert into medialibrary.tags(tag) 
            values (priorvalue);
        end if;
        
        set newtagid = (select tagid from tags t where t.tag = priorvalue);
        set newtrackid = (select trackid from tracks t where t.title = ttrack);
        
        if not exists (select * from tracktags tt where tt.trackid = newtrackid and tt.tagid = newtagid)
		then
			insert into tracktags values (newtrackid, newtagid); 
		end if;
        
        set counter = counter + 1;
    end while;
    
end \\
delimiter ;

call medialibrary.addtags('Dream Lover', 'Weird, Dippy, Actually okayish');
select * from tags;
