/* 
 * FeedItem before trigger
 *
 * History
 * -------
 * 03/17/2014 Justin Stouffer   Created
 *
 */
trigger FeedItemBefore on FeedItem (before insert, before update) {

	ChatterFilter.filterPost(trigger.new);

}