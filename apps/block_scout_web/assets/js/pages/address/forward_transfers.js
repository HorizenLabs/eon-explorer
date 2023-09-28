import $ from 'jquery'
import omit from 'lodash.omit'
import humps from 'humps'
import numeral from 'numeral'
import socket from '../../socket'
import { batchChannel } from '../../lib/utils'
import { connectElements } from '../../lib/redux_helpers.js'
import { createAsyncLoadStore } from '../../lib/async_listing_load'
import '../address'
import { isFiltered } from './utils'

const BATCH_THRESHOLD = 10

export const initialState = {
  channelDisconnected: false,
  addressHash: null,
  filter: null,
  forwardTransfersBatch: []
}

export function reducer (state, action) {
  switch (action.type) {
    case 'PAGE_LOAD':
    case 'ELEMENTS_LOAD': {
      return Object.assign({}, state, omit(action, 'type'))
    }
    case 'CHANNEL_DISCONNECTED': {
      if (state.beyondPageOne) return state

      return Object.assign({}, state, {
        channelDisconnected: true,
        forwardTransfersBatch: []
      })
    }
    case 'RECEIVED_NEW_FORWARD_TRANSFER_BATCH': {
      if (state.channelDisconnected || state.beyondPageOne) return state

      const incomingforwardTransfers = action.msgs
        .filter(({ toAddressHash, fromAddressHash }) => (
          !state.filter ||
          (state.filter === 'to' && toAddressHash === state.addressHash) ||
          (state.filter === 'from' && fromAddressHash === state.addressHash)
        )).map(msg => msg.forwardTransferHtml)

      if (!state.forwardTransfersBatch.length && incomingforwardTransfers.length < BATCH_THRESHOLD) {
        return Object.assign({}, state, {
          items: [
            ...incomingforwardTransfers.reverse(),
            ...state.items
          ]
        })
      } else {
        return Object.assign({}, state, {
          forwardTransfersBatch: [
            ...incomingforwardTransfers.reverse(),
            ...state.forwardTransfersBatch
          ]
        })
      }
    }
    default:
      return state
  }
}

const elements = {
  '[data-selector="channel-disconnected-message"]': {
    render ($el, state) {
      // @ts-ignore
      if (state.channelDisconnected && !window.loading) $el.show()
    }
  },
  '[data-selector="channel-batching-count"]': {
    render ($el, state) {
      const $channelBatching = $('[data-selector="channel-batching-message"]')
      if (!state.forwardTransfersBatch.length) return $channelBatching.hide()
      $channelBatching.show()
      $el[0].innerHTML = numeral(state.forwardTransfersBatch.length).format()
    }
  },
  '[data-test="filter_dropdown"]': {
    render ($el, state) {
      if (state.emptyResponse && !state.isSearch) {
        if (isFiltered(state.filter)) {
          $el.addClass('no-rm')
        } else {
          return $el.hide()
        }
      } else {
        $el.removeClass('no-rm')
      }

      return $el.show()
    }
  }
}

if ($('[data-page="address-forward-transfers"]').length) {
  window.onbeforeunload = () => {
    // @ts-ignore
    window.loading = true
  }

  const store = createAsyncLoadStore(reducer, initialState, 'dataset.identifier')
  const addressHash = $('[data-page="address-details"]')[0].dataset.pageAddressHash

  store.dispatch({ type: 'PAGE_LOAD', addressHash })
  connectElements({ store, elements })

  const addressChannel = socket.channel(`addresses:${addressHash}`, {})
  addressChannel.join()
  addressChannel.onError(() => store.dispatch({
    type: 'CHANNEL_DISCONNECTED'
  }))
  addressChannel.on('forward_transfer', batchChannel((msgs) => store.dispatch({
    type: 'RECEIVED_NEW_FORWARD_TRANSFER_BATCH',
    msgs: humps.camelizeKeys(msgs)
  })))
}
