# -*- coding: utf-8 -*-


def strip_string_custom(given_tender_uaid):
    strip_tender_ua_id = given_tender_uaid.strip()
    return strip_tender_ua_id


def get_complaint_index_by_id(tender_data):
    return tender_data['data'].get('complaints', [])[0]

