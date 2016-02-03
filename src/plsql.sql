-----------------
--    _____    --
-- -=[' - ']=- --
--   <[ : ]>   --
--     ] [     --
-----------------
function css_prop(
    p_name varchar2, 
    p_value varchar2
)
return varchar2
as
begin
  if p_value is null then
     return null;
  end if;
  
  return p_name || ':' || case when regexp_like(p_value,'^[0-9]+$') then p_value||'px' else p_value end  || '; ';
end css_prop;

procedure write_text_obj( 
    p_headline  varchar2,
    p_text      varchar2,
    p_link      varchar2 default null,
    p_link_text varchar2 default null,
    p_link_auth boolean  default true
)
as
begin

    apex_json.open_object('text');
        apex_json.write('text',     p_text || case when p_link is not null and p_link_auth then ' <p class="sb-edit-link" >' || apex_plugin_util.get_link(p_link, p_link_text) ||'</p>' end);
        apex_json.write('headline', p_headline);
    apex_json.close_object;

end write_text_obj;

procedure write_media_obj( 
    p_url     varchar2,
    p_caption varchar2,
    p_credit  varchar2
)
as
begin

    if p_url is not null then
        apex_json.open_object('media');
            apex_json.write('caption', p_caption);
            apex_json.write('credit',  p_credit);
            apex_json.write('url',     p_url);
            if regexp_like(p_url,'\.(gif|jpg|jpeg|tiff|png)\?*') then
                apex_json.write('thumbnail', p_url);
            end if;
        apex_json.close_object;
    end if;
    

end write_media_obj;

procedure write_date_obj(
    p_object_name  varchar2,
    p_date         date,
    p_date_format  varchar2 default null,
    p_include_time boolean  default false
)
as
    l_date date;
begin

    l_date := case when p_include_time then p_date else trunc(p_date) end;
    
    apex_json.open_object(p_object_name);
        apex_json.write('display_date', case when p_date_format is not null 
                                            then to_char(p_date,p_date_format) 
                                        end);                             
        apex_json.write('second', to_number(to_char(p_date,'SS')));
        apex_json.write('minute', to_number(to_char(p_date,'MI')));
        apex_json.write('hour',   to_number(to_char(p_date,'HH24')));
        apex_json.write('day',    to_number(to_char(p_date,'DD')));
        apex_json.write('month',  to_number(to_char(p_date,'MM'))); 
        apex_json.write('year',   to_number(to_char(p_date,'YYYY')));  
    apex_json.close_object;

end write_date_obj;

function render (
    p_region in apex_plugin.t_region,
    p_plugin in apex_plugin.t_plugin,
    p_is_printer_friendly in boolean
) return apex_plugin.t_region_render_result is

    c_width            constant varchar2(255) := p_region.attribute_15; 
    c_height           constant varchar2(255) := nvl(p_region.attribute_16,400);
    c_language         constant varchar2(10)  := apex_plugin_util.replace_substitutions(p_region.attribute_17);
    c_timenav_position constant varchar2(10)  := apex_plugin_util.replace_substitutions(p_region.attribute_18);   
    c_font             constant varchar2(255) := nvl(apex_plugin_util.replace_substitutions(p_region.attribute_19),'default');   
     
    l_timeline_id  varchar2(255);
    l_ndf_id       varchar2(255);
    l_onload_code  varchar2(32767);      

begin

    APEX_PLUGIN_UTIL.DEBUG_REGION (
        p_plugin              => p_plugin,
        p_region              => p_region,
        p_is_printer_friendly => p_is_printer_friendly
    );
    
    l_timeline_id := apex_escape.html_attribute(p_region.static_id || '_timeline');
    l_ndf_id      := apex_escape.html_attribute(p_region.static_id || '_ndf');
 
    sys.htp.p(
        '<div ' || apex_plugin_util.get_html_attr('id',l_timeline_id)|| apex_plugin_util.get_html_attr('style',css_prop('width',c_width) || css_prop('height',c_height)) ||'></div>'
    );
    
    sys.htp.p(
        '<div ' || apex_plugin_util.get_html_attr('id',l_ndf_id) || ' style="display:none">'|| p_region.no_data_found_message ||'</div>'
    );
    
    apex_css.add_file(
      p_name      => 'font.' || c_font,
      p_directory => p_plugin.file_prefix || 'css/fonts/'
    );
    
    
    l_onload_code := 'apex.jQuery("#' || p_region.static_id || '").timeline({' ||
       apex_javascript.add_attribute('timelineID',l_timeline_id) ||
       apex_javascript.add_attribute('ndfID',l_ndf_id) ||
       apex_javascript.add_attribute('timenav_position',c_timenav_position)||
       apex_javascript.add_attribute('language',c_language)||
       apex_javascript.add_attribute('pageItems', apex_plugin_util.page_item_names_to_jquery(p_region.ajax_items_to_submit)) ||
       apex_javascript.add_attribute('ajaxIdentifier', apex_plugin.get_ajax_identifier(), FALSE, FALSE) || 
    '});';

    apex_javascript.add_onload_code(
        p_code => l_onload_code
    );
    
    return null;
end render;

function ajax (
     p_region in apex_plugin.t_region,
     p_plugin in apex_plugin.t_plugin
) return apex_plugin.t_region_ajax_result is

    c_action constant varchar2(30)  := apex_application.g_x10;
    
    c_event_start_col        constant varchar2(35)   := p_region.attribute_06;
    c_event_end_col          constant varchar2(35)   := p_region.attribute_09;
    c_event_headline_col     constant varchar2(35)   := p_region.attribute_07;
    c_event_sub_headline_col constant varchar2(35)   := p_region.attribute_08;
    c_event_media_url_col    constant varchar2(35)   := p_region.attribute_10;
    c_event_group_col        constant varchar2(35)   := p_region.attribute_11;
    c_link_target            constant varchar2(2000) := p_region.attribute_13;
    c_link_text              constant varchar2(2000) := p_region.attribute_14;
    c_link_auth              constant varchar2(2000) := p_region.attribute_20;
    
    
    c_has_media_col          constant boolean := c_event_media_url_col IS NOT NULL;
    c_has_sub_headline_col   constant boolean := c_event_sub_headline_col IS NOT NULL;
    c_has_group_col          constant boolean := c_event_group_col IS NOT NULL; 
    c_has_end_col            constant boolean := c_event_end_col IS NOT NULL;
    
    l_column_value_list apex_plugin_util.t_column_value_list2;
    
    l_event_start_col_no        pls_integer;
    l_event_end_col_no          pls_integer;
    l_event_media_url_col_no    pls_integer;
    l_event_headline_col_no     pls_integer;
    l_event_sub_headline_col_no pls_integer;
    l_event_group_col_no        pls_integer;
    
    l_has_link_auth  boolean;
   
   -- Title variables
    l_headline          varchar2(255);
    l_sub_headline      varchar2(4000);
    l_media_url         varchar2(255);
    l_media_caption     varchar2(4000);
    l_media_credit      varchar2(255);
    
    --event variables
    l_event_start        date;
    l_event_start_fmt    varchar2(255);
    l_event_end          date;
    l_event_end_fmt      varchar2(255);
    l_event_headline     varchar2(255);
    l_event_sub_headline varchar2(4000);
    l_event_media_url    varchar2(4000);
    l_event_group        varchar2(255);
    l_event_has_time     boolean;
    l_event_link         varchar2(4000);
    l_event_link_text    varchar2(4000);

begin

    apex_plugin_util.debug_region(
        p_plugin        => p_plugin,
        p_region        => p_region
    );

    l_headline       := apex_plugin_util.replace_substitutions(p_region.attribute_01);
    l_sub_headline   := apex_plugin_util.replace_substitutions(p_region.attribute_02);
    l_media_url      := apex_plugin_util.replace_substitutions(p_region.attribute_03);
    l_media_caption  := apex_plugin_util.replace_substitutions(p_region.attribute_04);
    l_media_credit   := apex_plugin_util.replace_substitutions(p_region.attribute_05);
    l_event_has_time := p_region.attribute_12 = 'Y';
    
    if c_link_auth is not null then
      l_has_link_auth := apex_authorization.is_authorized(c_link_auth);
    else
      l_has_link_auth := true;
    end if;
    
    if c_action = 'DATA'
    then
       
       l_column_value_list := apex_plugin_util.get_data2(
            p_sql_statement => p_region.source,
            p_min_columns => 2,
            p_max_columns => null,
            p_component_name => p_region.name
        );
        
        for l_column_idx in 1.. p_region.region_columns.count loop
            l_column_value_list(l_column_idx).format_mask := p_region.region_columns(l_column_idx).format_mask;
        end loop;

        l_event_start_col_no := apex_plugin_util.get_column_no(
            p_attribute_label => 'Start Date',
            p_column_alias => c_event_start_col,
            p_column_value_list => l_column_value_list,
            p_is_required => true,
            p_data_type => apex_plugin_util.c_data_type_date
        );
        l_event_start_fmt := p_region.region_columns(l_event_start_col_no).format_mask;
        
        l_event_headline_col_no := apex_plugin_util.get_column_no(
            p_attribute_label => 'Title',
            p_column_alias => c_event_headline_col,
            p_column_value_list => l_column_value_list,
            p_is_required => true,
            p_data_type => apex_plugin_util.c_data_type_varchar2
        );
        
        if c_has_end_col then
            l_event_end_col_no := apex_plugin_util.get_column_no(
                p_attribute_label => 'End Date',
                p_column_alias => c_event_end_col,
                p_column_value_list => l_column_value_list,
                p_is_required => false,
                p_data_type => apex_plugin_util.c_data_type_date
            );
            l_event_end_fmt := p_region.region_columns(l_event_end_col_no).format_mask;
        end if;

        if c_has_group_col then
            l_event_group_col_no := apex_plugin_util.get_column_no(
                p_attribute_label => 'Group',
                p_column_alias => c_event_group_col,
                p_column_value_list => l_column_value_list,
                p_is_required => false,
                p_data_type => apex_plugin_util.c_data_type_varchar2
            );
        end if;

        if c_has_sub_headline_col then
            l_event_sub_headline_col_no := apex_plugin_util.get_column_no(
                p_attribute_label => 'Description',
                p_column_alias => c_event_sub_headline_col,
                p_column_value_list => l_column_value_list,
                p_is_required => false,
                p_data_type => apex_plugin_util.c_data_type_varchar2
            );    
        end if;

        if c_has_media_col then
            l_event_media_url_col_no := apex_plugin_util.get_column_no(
                p_attribute_label => 'Media URL',
                p_column_alias => c_event_media_url_col,
                p_column_value_list => l_column_value_list,
                p_is_required => false,
                p_data_type => apex_plugin_util.c_data_type_varchar2
            );   
        end if;
        apex_json.initialize_output(
          p_http_cache => false
        );
        apex_json.open_object;
            apex_json.open_object('title');
                write_text_obj(l_headline, l_sub_headline);
                if l_media_url is not null then
                   write_media_obj(l_media_url,l_media_caption,l_media_credit);
                end if;
            apex_json.close_object;
            apex_json.open_array('events');
                for l_row_num in 1 .. l_column_value_list(1).value_list.count
                loop

                    apex_plugin_util.set_component_values(
                        p_column_value_list => l_column_value_list,
                        p_row_num => l_row_num
                    );

                    l_event_start    := l_column_value_list(l_event_start_col_no).value_list(l_row_num).date_value;
                    l_event_headline := apex_plugin_util.get_value_as_varchar2(
                        p_data_type   => l_column_value_list(l_event_headline_col_no).data_type,
                        p_value       => l_column_value_list(l_event_headline_col_no).value_list(l_row_num),
                        p_format_mask => l_column_value_list(l_event_headline_col_no).format_mask
                    );
                    if c_link_target is not null then
                        l_event_link := wwv_flow_utilities.prepare_url(
                            apex_plugin_util.replace_substitutions (
                                p_value => c_link_target,
                                p_escape => false
                            )
                        );
                        l_event_link_text  := wwv_flow_utilities.prepare_url(
                            apex_plugin_util.replace_substitutions (
                                p_value => c_link_text,
                                p_escape => false
                            )
                        );
                    end if; 
                                                
                    if c_has_group_col then
                       l_event_group := apex_plugin_util.get_value_as_varchar2(
                            p_data_type   => l_column_value_list(l_event_group_col_no).data_type,
                            p_value       => l_column_value_list(l_event_group_col_no).value_list(l_row_num),
                            p_format_mask => l_column_value_list(l_event_group_col_no).format_mask
                        );
                    end if;
                    
                    if c_has_sub_headline_col then
                        l_event_sub_headline := apex_plugin_util.get_value_as_varchar2(
                            p_data_type   => l_column_value_list(l_event_sub_headline_col_no).data_type,
                            p_value       => l_column_value_list(l_event_sub_headline_col_no).value_list(l_row_num),
                            p_format_mask => l_column_value_list(l_event_sub_headline_col_no).format_mask
                        );
                    end if;

                    if c_has_media_col then
                        l_event_media_url :=apex_plugin_util.get_value_as_varchar2(
                            p_data_type   => l_column_value_list(l_event_media_url_col_no).data_type,
                            p_value       => l_column_value_list(l_event_media_url_col_no).value_list(l_row_num),
                            p_format_mask => l_column_value_list(l_event_media_url_col_no).format_mask
                        );
                    end if;
                    
                    if c_has_end_col then
                        l_event_end    := l_column_value_list(l_event_end_col_no).value_list(l_row_num).DATE_VALUE;
                    end if;                    
                    
                    apex_json.open_object;
                        if c_has_group_col then
                            apex_json.write('group', nvl(l_event_group,'none'));
                        end if;
                        if c_has_media_col then
                           write_media_obj(l_event_media_url,'','');
                        end if;
                        if c_has_end_col then
                          write_date_obj('end_date',l_event_end, l_event_end_fmt, l_event_has_time);
                        end if;
                        write_date_obj('start_date',l_event_start, l_event_start_fmt, l_event_has_time);
                        write_text_obj(l_event_headline,l_event_sub_headline,l_event_link,l_event_link_text,l_has_link_auth);
                    apex_json.close_object;
                 end loop;
                 apex_plugin_util.clear_component_values;
            apex_json.close_array;
        apex_json.close_object;
    end if; -- c_action potentially more in the future
    
    return null;
exception
    when others then
        apex_plugin_util.clear_component_values;
        raise;
end ajax;