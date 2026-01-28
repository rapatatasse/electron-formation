(function () {
  function csrfToken() {
    var el = document.querySelector('meta[name="csrf-token"]');
    return el ? el.getAttribute('content') : null;
  }

  function jsonHeaders() {
    var token = csrfToken();
    var headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (token) headers['X-CSRF-Token'] = token;
    return headers;
  }

  function parseDate(dateStr) {
    if (!dateStr) return null;
    return new Date(dateStr);
  }

  function formatDateISO(d) {
    if (!d) return null;
    var year = d.getFullYear();
    var month = String(d.getMonth() + 1).padStart(2, '0');
    var day = String(d.getDate()).padStart(2, '0');
    return year + '-' + month + '-' + day;
  }

  function openModal(task, users) {
    var modal = document.getElementById('gantt-task-modal');
    if (!modal) return;

    var titleEl = document.getElementById('gantt-modal-title');
    var form = document.getElementById('gantt-task-form');

    var inputId = document.getElementById('gantt_task_id');
    var inputName = document.getElementById('gantt_task_name');
    var inputStart = document.getElementById('gantt_task_start_date');
    var inputEnd = document.getElementById('gantt_task_end_date');
    var inputProgress = document.getElementById('gantt_task_progress');
    var inputStatus = document.getElementById('gantt_task_status');
    var inputPriority = document.getElementById('gantt_task_priority');
    var inputDesc = document.getElementById('gantt_task_description');
    var selectUsers = document.getElementById('gantt_task_user_ids');

    titleEl.textContent = 'Modifier tâche';

    inputId.value = task.id;
    inputName.value = task.text || '';
    inputStart.value = task.start_date || '';
    inputEnd.value = task.end_date || '';
    inputProgress.value = typeof task.progress === 'number' ? task.progress : 0;
    inputStatus.value = task.status || '';
    inputPriority.value = task.priority || '';
    inputDesc.value = task.description || '';

    while (selectUsers.firstChild) selectUsers.removeChild(selectUsers.firstChild);

    var assigned = Array.isArray(task.user_ids) ? task.user_ids.map(String) : [];
    users.forEach(function (u) {
      var opt = document.createElement('option');
      opt.value = String(u.id);
      opt.textContent = u.full_name + ' (' + u.email + ')';
      if (assigned.includes(String(u.id))) opt.selected = true;
      selectUsers.appendChild(opt);
    });

    modal.style.display = 'flex';

    function close() {
      modal.style.display = 'none';
      modal.removeEventListener('click', onOverlay);
      document.removeEventListener('keydown', onEsc);
    }

    function onOverlay(e) {
      if (e.target && (e.target.classList.contains('modal-overlay') || e.target.getAttribute('data-modal-close') === '1')) {
        close();
      }
    }

    function onEsc(e) {
      if (e.key === 'Escape') close();
    }

    modal.addEventListener('click', onOverlay);
    document.addEventListener('keydown', onEsc);

    form.onsubmit = function (e) {
      e.preventDefault();
      var projectId = form.getAttribute('data-project-id');

      var selectedIds = Array.prototype.slice.call(selectUsers.selectedOptions).map(function (o) { return parseInt(o.value, 10); });

      fetch('/bureau/tasks/' + encodeURIComponent(inputId.value) + '.json', {
        method: 'PATCH',
        headers: jsonHeaders(),
        body: JSON.stringify({
          task: {
            name: inputName.value,
            start_date: inputStart.value,
            end_date: inputEnd.value,
            progress: parseInt(inputProgress.value || '0', 10),
            status: inputStatus.value,
            priority: inputPriority.value,
            description: inputDesc.value,
            user_ids: selectedIds
          },
          project_id: projectId
        })
      }).then(function (r) {
        if (!r.ok) return r.json().then(function (j) { throw j; });
        return r.json();
      }).then(function (updated) {
        if (window.gantt) {
          var t = window.gantt.getTask(updated.id);
          t.text = updated.text;
          t.start_date = updated.start_date;
          t.end_date = updated.end_date;
          t.progress = updated.progress;
          t.status = updated.status;
          t.priority = updated.priority;
          t.description = updated.description;
          t.user_ids = updated.user_ids;
          window.gantt.updateTask(updated.id);
        }
        close();
      }).catch(function () {
      });
    };
  }

  function initGantt() {
    var container = document.getElementById('gantt_here');
    if (!container) return;

    var projectId = container.getAttribute('data-project-id');
    if (!projectId) return;

    if (!window.gantt) return;

    window.gantt.config.date_format = '%Y-%m-%d';
    window.gantt.config.drag_links = true;
    window.gantt.config.drag_progress = true;
    window.gantt.config.drag_resize = true;
    window.gantt.config.drag_move = true;

    window.gantt.config.columns = [
      { name: 'text', label: 'Tâche', tree: true, width: 240 },
      { name: 'start_date', label: 'Début', align: 'center', width: 90 },
      { name: 'end_date', label: 'Fin', align: 'center', width: 90 },
      { name: 'progress', label: '%', align: 'center', width: 60 }
    ];

    var usersCache = [];

    function loadUsers() {
      return fetch('/bureau/projects/' + encodeURIComponent(projectId) + '/gantt_users.json', {
        headers: { 'Accept': 'application/json' }
      }).then(function (r) { return r.json(); }).then(function (users) {
        usersCache = users;
        return users;
      });
    }

    function loadData() {
      return fetch('/bureau/projects/' + encodeURIComponent(projectId) + '/gantt_data.json', {
        headers: { 'Accept': 'application/json' }
      }).then(function (r) { return r.json(); });
    }

    window.gantt.attachEvent('onAfterTaskDrag', function (id) {
      var task = window.gantt.getTask(id);
      fetch('/bureau/tasks/' + encodeURIComponent(id) + '.json', {
        method: 'PATCH',
        headers: jsonHeaders(),
        body: JSON.stringify({
          task: {
            start_date: formatDateISO(task.start_date),
            end_date: formatDateISO(task.end_date),
            progress: Math.round((task.progress || 0) * 100)
          },
          project_id: projectId
        })
      }).then(function () {
      });
    });

    window.gantt.attachEvent('onAfterTaskUpdate', function (id, item) {
      fetch('/bureau/tasks/' + encodeURIComponent(id) + '.json', {
        method: 'PATCH',
        headers: jsonHeaders(),
        body: JSON.stringify({
          task: {
            name: item.text,
            start_date: item.start_date,
            end_date: item.end_date,
            progress: Math.round((item.progress || 0) * 100)
          },
          project_id: projectId
        })
      }).then(function () {
      });
    });

    window.gantt.attachEvent('onBeforeLightbox', function (id) {
      var task = window.gantt.getTask(id);
      var modalTask = {
        id: task.id,
        text: task.text,
        start_date: task.start_date ? formatDateISO(task.start_date) : task.start_date,
        end_date: task.end_date ? formatDateISO(task.end_date) : task.end_date,
        progress: Math.round((task.progress || 0) * 100),
        status: task.status,
        priority: task.priority,
        description: task.description,
        user_ids: task.user_ids
      };

      openModal(modalTask, usersCache);
      return false;
    });

    window.gantt.attachEvent('onAfterLinkAdd', function (id, link) {
      fetch('/bureau/task_dependencies.json', {
        method: 'POST',
        headers: jsonHeaders(),
        body: JSON.stringify({
          task_dependency: {
            task_id: link.target,
            dependency_task_id: link.source
          }
        })
      }).then(function (r) {
        if (!r.ok) return r.json().then(function (j) { throw j; });
        return r.json();
      }).then(function (created) {
        link._dependency_id = created.id;
      }).catch(function () {
        window.gantt.deleteLink(id);
      });
    });

    window.gantt.attachEvent('onBeforeLinkDelete', function (id, link) {
      var depId = link._dependency_id;
      if (!depId) return true;

      fetch('/bureau/task_dependencies/' + encodeURIComponent(depId) + '.json', {
        method: 'DELETE',
        headers: jsonHeaders()
      }).then(function () {
      });

      return true;
    });

    window.gantt.init('gantt_here');

    Promise.all([loadUsers(), loadData()]).then(function (res) {
      var data = res[1];

      var tasks = (data.tasks || []).map(function (t) {
        return {
          id: t.id,
          text: t.text,
          start_date: t.start_date,
          end_date: t.end_date,
          progress: (t.progress || 0) / 100,
          status: t.status,
          priority: t.priority,
          description: t.description,
          user_ids: t.user_ids
        };
      });

      var links = (data.links || []).map(function (l) {
        return {
          id: l.id,
          source: l.source,
          target: l.target,
          type: l.type,
          _dependency_id: l.dependency_id
        };
      });

      window.gantt.parse({ data: tasks, links: links });
    });
  }

  document.addEventListener('DOMContentLoaded', initGantt);
})();
