/* 
 * FeedComment before trigger
 *
 * History
 * -------
 * 03/17/2014 Justin Stouffer   Created
 *
 */
trigger FeedCommentBefore on FeedComment (before insert, before update) {
	
	ChatterFilter.filterComment(trigger.new);

}