import $ from 'jquery'
import omit from 'lodash.omit'
import humps from 'humps'
import numeral from 'numeral'
import socket from '../socket'
import { connectElements } from '../lib/redux_helpers.js'
import { batchChannel } from '../lib/utils'
import { createAsyncLoadStore } from '../lib/random_access_pagination'
import '../app'

const BATCH_THRESHOLD = 10

export const initialState = {
  channelDisconnected: false,
  feePaymentCount: null,
  feePaymentsBatch: []
}

export function reducer (state = initialState, action) {
  switch (action.type) {
    case 'ELEMENTS_LOAD': {
      return Object.assign({}, state, omit(action, 'type'))
    }
    case 'CHANNEL_DISCONNECTED': {
      return Object.assign({}, state, {
        channelDisconnected: true
      })
    }
    case 'RECEIVED_NEW_FEE_PAYMENT_BATCH': {
      if (state.channelDisconnected) return state

      const feePaymentCount = state.feePaymentCount + action.msgs.length
      const feePaymentHtml = action.msgs.map(message => message.transactionHtml)

      if (!state.feePaymentsBatch.length && action.msgs.length < BATCH_THRESHOLD) {
        return Object.assign({}, state, {
          items: [
            ...feePaymentHtml.reverse(),
            ...state.items
          ],
          feePaymentCount
        })
      } else {
        return Object.assign({}, state, {
          feePaymentsBatch: [
            ...feePaymentHtml.reverse(),
            ...state.feePaymentsBatch
          ],
          feePaymentCount
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
      if (state.channelDisconnected && !window.loading) $el.show()
    }
  },
  '[data-selector="channel-batching-count"]': {
    render ($el, state, oldState) {
      const $channelBatching = $('[data-selector="channel-batching-message"]')
      if (state.feePaymentsBatch.length) {
        $channelBatching.show()
        $el[0].innerHTML = numeral(state.feePaymentsBatch.length).format()
      } else {
        $channelBatching.hide()
      }
    }
  },
  '[data-selector="fee-payment-count"]': {
    load ($el) {
      return { feePaymentCount: numeral($el.text()).value() }
    },
    render ($el, state, oldState) {
      if (oldState.transactionCount === state.transactionCount) return
      $el.empty().append(numeral(state.transactionCount).format())
    }
  }
}

const $feePaymentsListPage = $('[data-page="fee-payment-list"]')
if ($feePaymentsListPage.length) {
  window.onbeforeunload = () => {
    window.loading = true
  }

  const store = createAsyncLoadStore(reducer, initialState, 'dataset.identifierHash')
  connectElements({ store, elements })

  const feePaymentsChannel = socket.channel('fee-payments:new_transaction')
  feePaymentsChannel.join()
  feePaymentsChannel.onError(() => store.dispatch({
    type: 'CHANNEL_DISCONNECTED'
  }))
  feePaymentsChannel.on('fee_payment', batchChannel((msgs) => store.dispatch({
    type: 'RECEIVED_NEW_FEE_PAYMENT_BATCH',
    msgs: humps.camelizeKeys(msgs)
  })))
}
