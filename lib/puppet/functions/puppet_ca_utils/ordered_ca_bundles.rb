# frozen_string_literal: true

require 'net/http'
require 'openssl'

Puppet::Functions.create_function(:'puppet_ca_utils::ordered_ca_bundles') do
  dispatch :ordered_pems do
    param 'Hash',   :certs_by_name
    param 'String', :ca_bundle
  end

  def ordered_pems(certs_by_name, ca_bundle)
    cert_scan = %r{-----BEGIN CERTIFICATE-----(?:.|\n)+?-----END CERTIFICATE-----}
    ca_certs = ca_bundle.scan(cert_scan).map { |crt| OpenSSL::X509::Certificate.new(crt) }
    pem_by_name(certs_by_name, ca_certs)
  end

  def pem_by_name(certs_by_name, x509_obj_array)
    certs_by_name.map { |name, cert_text|
      cert = OpenSSL::X509::Certificate.new(cert_text)
      ordered_obj_array = x509_obj_array.dup
      unless (idx = ordered_obj_array.find_index { |obj| obj.subject == cert.issuer })
        raise "missing ca cert for #{cert.subject} issuer"
      end
      [name,
       ordered_obj_array.unshift(ordered_obj_array.delete_at(idx))
                        .map { |obj| obj.to_pem }
                        .join('')
                        .encode('ascii')]
    }.to_h
  end
end
