timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false
  fCollapseAllNewStories: false
  fExpandAllNewAttachments: false

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'SET_TIME_TYPE'
      {timeType} = action
      return timm.set state, 'timeType', timeType

    when 'SET_SHOW_CLOSED_ACTIONS'
      {fShowClosedActions} = action
      return timm.set state, 'fShowClosedActions', fShowClosedActions

    when 'SET_COLLAPSE_ALL_NEW_STORIES'
      {fCollapseAllNewStories} = action
      return timm.set state, 'fCollapseAllNewStories', fCollapseAllNewStories

    when 'SET_EXPAND_ALL_NEW_ATTACHMENTS'
      {fExpandAllNewAttachments} = action
      return timm.set state, 'fExpandAllNewAttachments', fExpandAllNewAttachments

    else return state

module.exports = reducer
